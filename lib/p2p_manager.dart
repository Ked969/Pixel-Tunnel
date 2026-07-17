import 'dart:convert';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'models/stroke.dart';

class P2PManager {
  static final P2PManager _instance = P2PManager._internal();
  factory P2PManager() => _instance;
  P2PManager._internal();

  MqttServerClient? _mqttClient;

  String myId = "2";
  String friendId = "1";
  
  final String _secureTunnelSalt = "kedy_secret_tunnel_969x2026";

  Function(Stroke)? onStrokeReceived;
  Function()? onClearReceived;

  Future<void> init() async {
    await _initMQTT();
  }

  Future<void> _initMQTT() async {
    String uniqueClientId = 'client_${myId}_pixelTunnelPersistent';
    _mqttClient = MqttServerClient('broker.emqx.io', uniqueClientId);
    _mqttClient!.port = 1883;
    _mqttClient!.keepAlivePeriod = 60;
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(uniqueClientId)
        .startClean(); 
    _mqttClient!.connectionMessage = connMessage;

    try {
      await _mqttClient!.connect();
      _mqttClient!.subscribe("pixel_tunnel/$_secureTunnelSalt/$friendId/strokes", MqttQos.atLeastOnce);
      
      _mqttClient!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        
        final Map<String, dynamic> data = jsonDecode(payload);
        
        if (data.containsKey('action') && data['action'] == 'clear') {
          if (onClearReceived != null) {
            onClearReceived!();
          }
        } else {
          Stroke incomingStroke = Stroke.fromJson(data);
          if (onStrokeReceived != null) {
            onStrokeReceived!(incomingStroke);
          }
        }
      });
    } catch (_) {}
  }

  void sendStroke(Stroke stroke) {
    if (_mqttClient != null && _mqttClient!.connectionStatus!.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(stroke.toJson()));
      
      _mqttClient!.publishMessage(
        "pixel_tunnel/$_secureTunnelSalt/$myId/strokes",
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: true,
      );
    }
  }

  void sendClearAction() {
    if (_mqttClient != null && _mqttClient!.connectionStatus!.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode({'action': 'clear'}));
      
      _mqttClient!.publishMessage(
        "pixel_tunnel/$_secureTunnelSalt/$myId/strokes",
        MqttQos.atMostOnce,
        builder.payload!,
        retain: true,
      );
    }
  }
}
