# improv_wifi_flutter

Flutter plugin that wraps vendored `improv-wifi` native sources directly inside
the plugin.

- Android sources live under `android/src/main/kotlin/com/wifi/improv`
- iOS sources live under `ios/Classes/ImprovSDK`

The plugin exposes a small cross-platform API for:

- reading Bluetooth state
- scanning for Improv devices
- connecting to a discovered device
- sending the `identify` command
- provisioning Wi-Fi credentials
- listening to native Improv events through a Dart stream
- decoding fragmented RPC result notifications when devices use small BLE MTU

## Licensing

This package is distributed under the Apache License 2.0.

It includes vendored source code derived from the upstream `improv-wifi`
Android and iOS SDK repositories, with local modifications for Flutter plugin
integration and fragmented RPC result parsing support. See `NOTICE` for
attribution details.

## Installation

Add the plugin to your Flutter app:

```yaml
dependencies:
  improv_wifi_flutter:
    path: ../improv_wifi_flutter
```

## Platform requirements

- Android `minSdk 21`
- iOS `15.0+`

## Permissions

This plugin does not request runtime permissions for you.

### Android

Review the Bluetooth permission requirements for your target Android versions.
At minimum, apps typically need `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT`, and on
older Android versions may also need location permission for BLE scanning.

### iOS

Add `NSBluetoothAlwaysUsageDescription` to your `Info.plist`.

## Usage

```dart
import 'dart:async';

import 'package:improv_wifi_flutter/improv_wifi_flutter.dart';

final plugin = ImprovWifiFlutter();
late final StreamSubscription<ImprovWifiEvent> subscription;

Future<void> setup() async {
  final state = await plugin.getBluetoothState();
  print('Bluetooth state: ${state.name}');

  subscription = plugin.events.listen((event) {
    print('Event: ${event.type.name}');
    if (event.device != null) {
      print('Device: ${event.device!.id}');
    }
  });

  await plugin.startScan();
}
```

To connect and provision a device:

```dart
await plugin.connectToDevice(deviceId);
await plugin.identifyDevice();
await plugin.sendWifi(ssid: 'MyWiFi', password: 'secret');
```

## Event model

The plugin emits `ImprovWifiEvent` objects through `events`.

Possible event types:

- `bluetoothStateChanged`
- `scanningStateChanged`
- `deviceFound`
- `connectionStateChanged`
- `deviceStateChanged`
- `errorStateChanged`
- `rpcResult`
- `scanFailed`

## Notes

- Android device identifiers are BLE MAC addresses.
- iOS device identifiers are `CBPeripheral.identifier.uuidString`.
- `connectToDevice` expects a device that has already been discovered during the
  current scan session.
- The underlying Android SDK does not currently expose a public disconnect API,
  so this wrapper intentionally keeps the public Dart API focused on the shared
  feature set available on both platforms.
- The vendored Android and iOS BLE managers accumulate `RPC Result` bytes across
  multiple notifications and only decode once a full packet has been received.
