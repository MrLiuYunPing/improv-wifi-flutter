import 'package:flutter_test/flutter_test.dart';
import 'package:improv_wifi_flutter/improv_wifi_flutter.dart';
import 'package:improv_wifi_flutter/improv_wifi_flutter_platform_interface.dart';
import 'package:improv_wifi_flutter/improv_wifi_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockImprovWifiFlutterPlatform
    with MockPlatformInterfaceMixin
    implements ImprovWifiFlutterPlatform {
  @override
  Stream<ImprovWifiEvent> get events => const Stream<ImprovWifiEvent>.empty();

  @override
  Future<ImprovBluetoothState> getBluetoothState() {
    return Future<ImprovBluetoothState>.value(ImprovBluetoothState.poweredOn);
  }

  @override
  Future<void> startScan() async {}

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> connectToDevice(String deviceId) async {}

  @override
  Future<void> identifyDevice() async {}

  @override
  Future<void> sendWifi({
    required String ssid,
    required String password,
  }) async {}
}

void main() {
  final ImprovWifiFlutterPlatform initialPlatform =
      ImprovWifiFlutterPlatform.instance;

  test('$MethodChannelImprovWifiFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelImprovWifiFlutter>());
  });

  test('getBluetoothState', () async {
    const ImprovWifiFlutter improvWifiFlutterPlugin = ImprovWifiFlutter();
    final MockImprovWifiFlutterPlatform fakePlatform =
        MockImprovWifiFlutterPlatform();
    ImprovWifiFlutterPlatform.instance = fakePlatform;

    expect(
      await improvWifiFlutterPlugin.getBluetoothState(),
      ImprovBluetoothState.poweredOn,
    );
  });
}
