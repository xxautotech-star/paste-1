class Schedule {
  final int? id;
  final String deviceId;
  final String widgetId;
  final String widgetLabel;
  final String mqttTopic;
  final String command;
  final DateTime scheduledAt;
  final bool alternateMode;
  final int alternateInterval;
  final int alternateCount;
  final bool isActive;
  final bool isRecurring;
  final List<int> repeatDays;

  Schedule({
    this.id,
    required this.deviceId,
    required this.widgetId,
    required this.widgetLabel,
    required this.mqttTopic,
    required this.command,
    required this.scheduledAt,
    this.alternateMode = false,
    this.alternateInterval = 1000,
    this.alternateCount = 10,
    this.isActive = true,
    this.isRecurring = false,
    this.repeatDays = const [],
  });

  factory Schedule.fromJson(Map<String, dynamic> j) => Schedule(
        id: j['id'],
        deviceId: j['device_id'],
        widgetId: j['widget_id'],
        widgetLabel: j['widget_label'] ?? '',
        mqttTopic: j['mqtt_topic'],
        command: j['command'],
        scheduledAt: DateTime.parse(j['scheduled_at']),
        alternateMode: j['alternate_mode'] ?? false,
        alternateInterval: j['alternate_interval'] ?? 1000,
        alternateCount: j['alternate_count'] ?? 10,
        isActive: j['is_active'] ?? true,
        isRecurring: j['is_recurring'] ?? false,
        repeatDays: (j['repeat_days'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'widget_id': widgetId,
        'widget_label': widgetLabel,
        'mqtt_topic': mqttTopic,
        'command': command,
        'scheduled_at': scheduledAt.toIso8601String(),
        'alternate_mode': alternateMode,
        'alternate_interval': alternateInterval,
        'alternate_count': alternateCount,
        'is_recurring': isRecurring,
        'repeat_days': repeatDays,
      };
}