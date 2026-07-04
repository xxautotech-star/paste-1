import 'package:flutter/foundation.dart';

/// Global power state keyed by mqtt_topic
class DevicePowerState {
  DevicePowerState._();
  static final ValueNotifier<Map<String, bool>> notifier =
      ValueNotifier(<String, bool>{});

  static bool get(String topic) => notifier.value[topic] ?? false;

  static void set(String topic, bool value) {
    notifier.value = Map<String, bool>.from(notifier.value)..[topic] = value;
  }
}