import 'package:flutter_test/flutter_test.dart';
import 'package:improv_wifi_flutter/improv_wifi_flutter.dart';

void main() {
  test('parses event payloads from the native layer', () {
    final event = ImprovWifiEvent.fromMap(<Object?, Object?>{
      'type': 'deviceFound',
      'device': <Object?, Object?>{
        'id': 'AA:BB:CC:DD',
        'name': 'Kitchen Sensor',
      },
    });

    expect(event.type, ImprovWifiEventType.deviceFound);
    expect(event.device?.id, 'AA:BB:CC:DD');
    expect(event.device?.name, 'Kitchen Sensor');
  });
}
