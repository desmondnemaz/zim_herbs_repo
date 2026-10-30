import 'package:zim_herbs_repo/core/utils/enums.dart';

/// Represents a single event/stage in the record's validation history timeline.
class RecordAuditEntry {
  final RecordValidationStatus stage;
  final String? actorId;
  final String? actorName;
  final String? actorRole;
  final DateTime? timestamp;
  final String? notes;
  final bool isCompleted;
  final bool isCurrent;

  const RecordAuditEntry({
    required this.stage,
    this.actorId,
    this.actorName,
    this.actorRole,
    this.timestamp,
    this.notes,
    this.isCompleted = false,
    this.isCurrent = false,
  });
}
