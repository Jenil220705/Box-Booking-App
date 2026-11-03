enum NotificationType {
  booking,
  reminder,
  conflict,
  info,
  success;

  static NotificationType parse(String? v) => NotificationType.values
      .firstWhere((e) => e.name == v, orElse: () => NotificationType.info);
}

/// In-app notification. Like the web app these are stored on the device only
/// (there is no notifications table in Supabase).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.read = false,
  });

  /// Unique; reminders use a deterministic id so they are only raised once.
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    title: title,
    message: message,
    type: type,
    createdAt: createdAt,
    read: read ?? this.read,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
  };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String,
    title: j['title'] as String,
    message: j['message'] as String,
    type: NotificationType.parse(j['type'] as String?),
    createdAt:
        DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    read: j['read'] == true,
  );
}
