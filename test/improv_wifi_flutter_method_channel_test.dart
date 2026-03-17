import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:improv_wifi_flutter/improv_wifi_flutter_method_channel.dart';
import 'package:improv_wifi_flutter/src/improv_wifi_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelImprovWifiFlutter platform =
      MethodChannelImprovWifiFlutter();
  const MethodChannel channel = MethodChannel('improv_wifi_flutter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getBluetoothState':
              return 'poweredOn';
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getBluetoothState', () async {
    expect(await platform.getBluetoothState(), ImprovBluetoothState.poweredOn);
  });
}
