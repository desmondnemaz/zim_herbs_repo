import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';

/// ==============================================================================
/// USER PRESENCE & ONLINE TRACKING SERVICE
/// ==============================================================================
///
/// Architectural Overview (Hybrid Presence Model):
/// 1. Realtime Presence (WebSocket / Ephemeral):
///    - Connects to the Supabase Realtime channel 'online_presence'.
///    - Each active device tracks its user metadata using `channel.track(...)`.
///    - Zero database load: joins, state synchronizations, and socket disconnects
///      are handled in-memory by Supabase Realtime cluster.
///    - The service exposes [onlineUserIds] and [onlineUserCount] as [ValueNotifier]s
///      for immediate reactive UI updates in the Admin Console and Telemedicine.
///
/// 2. Persistent Activity (PostgreSQL Heartbeat):
///    - Updates `last_seen_at` on `public.user_profiles`.
///    - Strictly throttled with [heartbeatCooldown] (default: 5 minutes) to avoid
///      unnecessary database write spikes.
///    - Triggered on initial login, app resume from background, and manual actions.
///
/// Manual Maintenance Guide:
/// - To adjust how long a user is considered "Online" after their last heartbeat
///   when socket presence is unavailable, tune [onlineThreshold].
/// - To adjust how often the database is touched, tune [heartbeatCooldown].
/// - When user logs out, call [stopTracking] to immediately untrack presence.
/// ==============================================================================
class UserPresenceService with WidgetsBindingObserver {
  // Singleton pattern for application-wide presence access
  static final UserPresenceService _instance = UserPresenceService._internal();
  factory UserPresenceService() => _instance;
  UserPresenceService._internal();

  /// Supabase client instance
  final SupabaseClient _client = Supabase.instance.client;

  /// Dedicated channel name for tracking online users
  static const String presenceChannelName = 'online_presence';

  /// How frequently the client may update `last_seen_at` in Postgres
  static const Duration heartbeatCooldown = Duration(minutes: 5);

  /// Offline threshold: if not in Realtime Presence, a user seen within this
  /// duration is still considered recently active/online.
  static const Duration onlineThreshold = Duration(minutes: 5);

  /// Active Realtime channel
  RealtimeChannel? _presenceChannel;

  /// Current user model being tracked
  UserModel? _currentUser;

  /// Timestamp of the last successful database update to prevent write spam
  DateTime? _lastHeartbeatTime;

  /// Reactive set of user IDs currently connected via Realtime Presence
  final ValueNotifier<Set<String>> onlineUserIds = ValueNotifier<Set<String>>(<String>{});

  /// Reactive total count of unique online users
  final ValueNotifier<int> onlineUserCount = ValueNotifier<int>(0);

  /// Whether the service is currently observing app lifecycle
  bool _isObserverRegistered = false;

  /// Initializes presence tracking for the logged-in [user].
  ///
  /// Safe to call repeatedly on auth changes; re-subscribes only if user changes.
  Future<void> startTracking(UserModel user) async {
    // If already tracking the same user with an open channel, just refresh heartbeat
    if (_currentUser?.id == user.id && _presenceChannel != null) {
      _currentUser = user;
      unawaited(recordHeartbeat(force: false));
      return;
    }

    // Clean up any existing channel before starting a new one
    await stopTracking();

    _currentUser = user;

    // Register lifecycle observer to handle app minimize / resume
    if (!_isObserverRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _isObserverRegistered = true;
    }

    try {
      // 1. Establish Realtime Presence Channel
      _presenceChannel = _client.channel(presenceChannelName);

      // Listen for presence synchronization events across all connected clients
      _presenceChannel!.onPresenceSync((_) {
        _syncPresenceState();
      });

      // Subscribe and track this user's state
      _presenceChannel!.subscribe((status, error) async {
        if (status == RealtimeSubscribeStatus.subscribed && _currentUser != null) {
          try {
            await _presenceChannel?.track({
              'user_id': _currentUser!.id,
              'name': _currentUser!.name,
              'role': _currentUser!.role.name,
              'is_staff': _currentUser!.canModerate,
              'online_at': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            debugPrint('[UserPresenceService] Failed to track presence: $e');
          }
        }
      });

      // 2. Record initial persistent heartbeat in Postgres
      unawaited(recordHeartbeat(force: true));
    } catch (e) {
      debugPrint('[UserPresenceService] Error initializing presence channel: $e');
    }
  }

  /// Stops tracking presence and releases the WebSocket channel.
  ///
  /// Call this on user sign-out or account deactivation.
  Future<void> stopTracking() async {
    if (_presenceChannel != null) {
      try {
        await _presenceChannel?.untrack();
        await _client.removeChannel(_presenceChannel!);
      } catch (e) {
        debugPrint('[UserPresenceService] Error stopping presence channel: $e');
      } finally {
        _presenceChannel = null;
      }
    }

    _currentUser = null;
    onlineUserIds.value = <String>{};
    onlineUserCount.value = 0;

    if (_isObserverRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserverRegistered = false;
    }
  }

  /// Synchronizes the in-memory presence state from the Realtime channel.
  void _syncPresenceState() {
    if (_presenceChannel == null) return;

    try {
      final state = _presenceChannel!.presenceState();
      final Set<String> activeIds = <String>{};

      for (final clientState in state) {
        for (final presence in clientState.presences) {
          final payload = presence.payload;
          final userId = payload['user_id'] as String?;
          if (userId != null && userId.isNotEmpty) {
            activeIds.add(userId);
          }
        }
      }

      onlineUserIds.value = activeIds;
      onlineUserCount.value = activeIds.length;
    } catch (e) {
      debugPrint('[UserPresenceService] Error syncing presence state: $e');
    }
  }

  /// Records a persistent heartbeat in `user_profiles.last_seen_at`.
  ///
  /// Throttled to run at most once per [heartbeatCooldown] unless [force] is true.
  Future<void> recordHeartbeat({bool force = false}) async {
    final user = _currentUser;
    if (user == null) return;

    final now = DateTime.now();
    if (!force && _lastHeartbeatTime != null) {
      if (now.difference(_lastHeartbeatTime!) < heartbeatCooldown) {
        return; // Throttled: do not spam the database
      }
    }

    _lastHeartbeatTime = now;

    try {
      await _client.from('user_profiles').update({
        'last_seen_at': now.toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      // Non-fatal: if offline or temporary network issue, do not crash
      debugPrint('[UserPresenceService] Could not update last_seen_at: $e');
    }
  }

  /// Checks if a user is currently considered online.
  ///
  /// Returns `true` if:
  /// 1. The user's ID is actively present in the Realtime Presence channel, OR
  /// 2. The user's persistent [lastSeenAt] timestamp is within [onlineThreshold].
  bool isUserOnline(String userId, {DateTime? lastSeenAt}) {
    if (onlineUserIds.value.contains(userId)) {
      return true;
    }
    if (lastSeenAt != null) {
      final difference = DateTime.now().difference(lastSeenAt);
      return difference <= onlineThreshold;
    }
    return false;
  }

  /// Formats a human-readable "Last seen" description.
  ///
  /// Example outputs:
  /// - "Online now"
  /// - "Active 3m ago"
  /// - "Active 2h ago"
  /// - "Yesterday"
  /// - "Never active"
  String formatLastSeen(String userId, {DateTime? lastSeenAt}) {
    if (isUserOnline(userId, lastSeenAt: lastSeenAt)) {
      return 'Online now';
    }
    if (lastSeenAt == null) {
      return 'Offline';
    }

    final diff = DateTime.now().difference(lastSeenAt);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${lastSeenAt.day}/${lastSeenAt.month}/${lastSeenAt.year}';
    }
  }

  // ============================================================================
  // FLUTTER LIFECYCLE MANAGEMENT
  // ============================================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // When app returns to foreground: re-track presence and update last_seen_at
        if (_currentUser != null) {
          unawaited(startTracking(_currentUser!));
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // When app is minimized or hidden: untrack socket presence immediately
        _presenceChannel?.untrack();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }
}

