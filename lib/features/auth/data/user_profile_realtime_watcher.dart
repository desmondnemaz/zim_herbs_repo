import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Subscribes to Supabase Realtime UPDATE events for a single user's
/// `user_profiles` row and calls [onChange] whenever the server pushes one.
///
/// Requires `user_profiles` to be in the `supabase_realtime` publication
/// (see docs/migrations/enable_realtime_user_profiles.sql).
class UserProfileRealtimeWatcher {
  UserProfileRealtimeWatcher(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  String? _watchedUserId;

  String? get watchedUserId => _watchedUserId;

  /// Starts watching [userId]. Calling again for the same user is a no-op, so
  /// repeated auth events (e.g. hourly token refresh) don't open new channels.
  void watch(String userId, {required void Function() onChange}) {
    if (_watchedUserId == userId && _channel != null) return;
    stop();

    _watchedUserId = userId;
    _channel = _client
        .channel('user_profile_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'user_profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe((status, error) {
          // After every (re)join, refetch once so changes made while the
          // socket was disconnected are not missed.
          if (status == RealtimeSubscribeStatus.subscribed) onChange();
          // channelError / timedOut: realtime_client retries automatically;
          // the cached profile stays in place, so the UI is unaffected.
        });
  }

  /// Stops watching and releases the channel. Safe to call repeatedly.
  ///
  /// Local state is cleared synchronously; the network unsubscribe runs in the
  /// background so sign-out is never delayed (e.g. when offline).
  void stop() {
    final channel = _channel;
    _channel = null;
    _watchedUserId = null;
    if (channel != null) {
      unawaited(
        _client.removeChannel(channel).catchError((Object _) => 'error'),
      );
    }
  }
}
