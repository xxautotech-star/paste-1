import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
 // Remove or comment this out


class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  MqttServerClient? _client;
  bool _connected = false;

  final _statusController = StreamController<Map<String, String>>.broadcast();
  final _messageController = StreamController<Map<String, String>>.broadcast();

  Stream<Map<String, String>> get onStatusUpdate => _statusController.stream;
  Stream<Map<String, String>> get onMessage => _messageController.stream;

  Future<void> connect() async {
    if (_connected) return;

    final clientId = 'xxapp_${DateTime.now().millisecondsSinceEpoch}';

    _client = MqttServerClient(
  'wss://mqtt.xxsmartsystems.com',
  clientId,
);

_client!.port = 443;
_client!.useWebSocket = true;
_client!.websocketProtocols = MqttClientConstants.protocolsSingleDefault;

    _client!.keepAlivePeriod = 30;
    _client!.autoReconnect = true;
    _client!.logging(on: false);

    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.onAutoReconnected = _onReconnected;

    final connMsg = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client!.connectionMessage = connMsg;

    try {
  await _client!.connect();
} catch (e) {
  _connected = false;
  _client!.disconnect();
}
  }

  void _onConnected() {
    _connected = true;
    _client!.subscribe('xxsmart/devices/+/status', MqttQos.atLeastOnce);
    _client!.subscribe('xxsmart/devices/+/sensors', MqttQos.atLeastOnce);
    _client!.subscribe('devices/+/commands', MqttQos.atLeastOnce);
    _client!.subscribe('devices/+/data', MqttQos.atLeastOnce);
    
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final msg in messages) {
        final topic = msg.topic;
        final payload = MqttPublishPayload.bytesToStringAsString(
          (msg.payload as MqttPublishMessage).payload.message,
        );
        final parts = topic.split('/');

        // Handle status and sensors
        if (parts.length == 4 && parts[0] == 'xxsmart') {
          final deviceTopic = parts[2];
          final type = parts[3];
          if (type == 'status') {
            _statusController.add({'topic': deviceTopic, 'status': payload});
          } else if (type == 'sensors') {
            _messageController.add({'topic': deviceTopic, 'data': payload});
          }
        }

        // Handle commands (from scheduler)
        if (topic.startsWith('devices/') && topic.endsWith('/commands')) {
          _messageController.add({'topic': topic, 'command': payload});
        }

        // Handle sensor data
        if (topic.startsWith('devices/') && topic.endsWith('/data')) {
          final deviceId = parts[1];
          _messageController.add({'topic': deviceId, 'data': payload});
        }
      }
    });
  }

  void _onDisconnected() => _connected = false;

  void _onReconnected() {
    _connected = true;
    _client!.subscribe('xxsmart/devices/+/status', MqttQos.atLeastOnce);
    _client!.subscribe('xxsmart/devices/+/sensors', MqttQos.atLeastOnce);
    _client!.subscribe('devices/+/commands', MqttQos.atLeastOnce);
    _client!.subscribe('devices/+/data', MqttQos.atLeastOnce);
    
    
  }

  void disconnect() {
    _client?.disconnect();
    _connected = false;
  }

  bool get isConnected => _connected;
}