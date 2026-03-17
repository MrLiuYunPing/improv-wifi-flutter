import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'improv_wifi_flutter_platform_interface.dart';
import 'src/improv_wifi_models.dart';

/// An implementation of [ImprovWifiFlutterPlatform] that uses method channels.
class MethodChannelImprovWifiFlutter extends ImprovWifiFlutterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('improv_wifi_flutter');

  @visibleForTesting
  final eventChannel = const EventChannel('improv_wifi_flutter/events');

  Stream<ImprovWifiEvent>? _events;

  @override
  Stream<ImprovWifiEvent> get events {
    return _events ??= eventChannel.receiveBroadcastStream().map((
      dynamic event,
    ) {
      final map = Map<Object?, Object?>.from(event as Map<dynamic, dynamic>);
      return ImprovWifiEvent.fromMap(map);
    });
  }

  @override
  Future<ImprovBluetoothState> getBluetoothState() async {
    final state = await methodChannel.invokeMethod<String>('getBluetoothState');
    return ImprovBluetoothState.fromName(state);
  }

  @override
  Future<void> startScan() {
    return methodChannel.invokeMethod<void>('startScan');
  }

  @override
  Future<void> stopScan() {
    return methodChannel.invokeMethod<void>('stopScan');
  }

  @override
  Future<void> connectToDevice(String deviceId) {
    return methodChannel.invokeMethod<void>(
      'connectToDevice',
      <String, Object?>{'deviceId': deviceId},
    );
  }

  @override
  Future<void> identifyDevice() {
    return methodChannel.invokeMethod<void>('identifyDevice');
  }

  @override
  Future<void> sendWifi({required String ssid, required String password}) {
    return methodChannel.invokeMethod<void>('sendWifi', <String, Object?>{
      'ssid': ssid,
      'password': password,
    });
  }
}
