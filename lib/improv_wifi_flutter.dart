export 'src/improv_wifi_models.dart';
import 'improv_wifi_flutter_platform_interface.dart';
import 'src/improv_wifi_models.dart';

class ImprovWifiFlutter {
  const ImprovWifiFlutter();

  Stream<ImprovWifiEvent> get events =>
      ImprovWifiFlutterPlatform.instance.events;

  Future<ImprovBluetoothState> getBluetoothState() {
    return ImprovWifiFlutterPlatform.instance.getBluetoothState();
  }

  Future<void> startScan() {
    return ImprovWifiFlutterPlatform.instance.startScan();
  }

  Future<void> stopScan() {
    return ImprovWifiFlutterPlatform.instance.stopScan();
  }

  Future<void> connectToDevice(String deviceId) {
    return ImprovWifiFlutterPlatform.instance.connectToDevice(deviceId);
  }

  Future<void> identifyDevice() {
    return ImprovWifiFlutterPlatform.instance.identifyDevice();
  }

  Future<void> sendWifi({required String ssid, required String password}) {
    return ImprovWifiFlutterPlatform.instance.sendWifi(
      ssid: ssid,
      password: password,
    );
  }
}
