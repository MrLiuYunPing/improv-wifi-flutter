import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'improv_wifi_flutter_method_channel.dart';
import 'src/improv_wifi_models.dart';

abstract class ImprovWifiFlutterPlatform extends PlatformInterface {
  /// Constructs a ImprovWifiFlutterPlatform.
  ImprovWifiFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static ImprovWifiFlutterPlatform _instance = MethodChannelImprovWifiFlutter();

  /// The default instance of [ImprovWifiFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelImprovWifiFlutter].
  static ImprovWifiFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ImprovWifiFlutterPlatform] when
  /// they register themselves.
  static set instance(ImprovWifiFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<ImprovWifiEvent> get events {
    throw UnimplementedError('events has not been implemented.');
  }

  Future<ImprovBluetoothState> getBluetoothState() {
    throw UnimplementedError('getBluetoothState() has not been implemented.');
  }

  Future<void> startScan() {
    throw UnimplementedError('startScan() has not been implemented.');
  }

  Future<void> stopScan() {
    throw UnimplementedError('stopScan() has not been implemented.');
  }

  Future<void> connectToDevice(String deviceId) {
    throw UnimplementedError('connectToDevice() has not been implemented.');
  }

  Future<void> identifyDevice() {
    throw UnimplementedError('identifyDevice() has not been implemented.');
  }

  Future<void> sendWifi({required String ssid, required String password}) {
    throw UnimplementedError('sendWifi() has not been implemented.');
  }
}
