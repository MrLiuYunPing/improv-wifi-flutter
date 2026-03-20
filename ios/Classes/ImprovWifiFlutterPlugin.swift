import Flutter
import CoreBluetooth

public class ImprovWifiFlutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, ImprovManagerDelegate {
  private let improvManager: any ImprovManagerProtocol = ImprovManager.shared
  private var eventSink: FlutterEventSink?
  private var knownDeviceIds = Set<String>()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = ImprovWifiFlutterPlugin()
    let channel = FlutterMethodChannel(name: "improv_wifi_flutter", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "improv_wifi_flutter/events", binaryMessenger: registrar.messenger())

    registrar.addMethodCallDelegate(instance, channel: channel)
    eventChannel.setStreamHandler(instance)
  }

  override init() {
    super.init()
    improvManager.delegate = self
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getBluetoothState":
      result(mapBluetoothState(improvManager.bluetoothState))
    case "startScan":
      improvManager.reset()
      improvManager.scan()
      result(nil)
    case "stopScan":
      improvManager.stopScan()
      result(nil)
    case "connectToDevice":
      guard let args = call.arguments as? [String: Any],
            let deviceId = args["deviceId"] as? String,
            let peripheral = improvManager.foundDevices[deviceId] else {
        result(FlutterError(code: "device_not_found", message: "Device must be discovered before connecting.", details: nil))
        return
      }
      improvManager.connectToDevice(peripheral)
      result(nil)
    case "identifyDevice":
      if let error = improvManager.identifyDevice() {
        result(flutterError(from: error))
      } else {
        result(nil)
      }
    case "sendWifi":
      guard let args = call.arguments as? [String: Any],
            let ssid = args["ssid"] as? String,
            let password = args["password"] as? String else {
        result(FlutterError(code: "invalid_argument", message: "ssid and password are required.", details: nil))
        return
      }

      if let error = improvManager.sendWifi(ssid: ssid, password: password) {
        result(flutterError(from: error))
      } else {
        result(nil)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    emitEvent(
      type: "bluetoothStateChanged",
      extra: ["bluetoothState": mapBluetoothState(improvManager.bluetoothState)]
    )
    emitEvent(
      type: "scanningStateChanged",
      extra: ["isScanning": improvManager.scanInProgress]
    )
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  public func didUpdateBluetoohState(_ state: CBManagerState) {
    emitEvent(
      type: "bluetoothStateChanged",
      extra: ["bluetoothState": mapBluetoothState(state)]
    )
  }

  public func didUpdateFoundDevices(devices: [String : CBPeripheral]) {
    for (deviceId, peripheral) in devices where !knownDeviceIds.contains(deviceId) {
      emitEvent(type: "deviceFound", extra: ["device": deviceMap(from: peripheral)])
    }
    knownDeviceIds = Set(devices.keys)
  }

  public func didConnect(peripheral: CBPeripheral) {
    if peripheral.state == .connected {
      emitEvent(
        type: "connectionStateChanged",
        extra: ["device": deviceMap(from: peripheral)]
      )
    } else {
      emitEvent(type: "connectionStateChanged")
    }
  }

  public func didDisconnect(peripheral _: CBPeripheral) {
    emitEvent(type: "connectionStateChanged")
  }

  public func didUpdateDeviceState(_ state: DeviceState?) {
    var extra = [String: Any]()
    if let stateName = mapDeviceState(state) {
      extra["deviceState"] = stateName
    }
    emitEvent(type: "deviceStateChanged", extra: extra)
  }

  public func didUpdateErrorState(_ state: ErrorState?) {
    var extra = [String: Any]()
    if let stateName = mapErrorState(state) {
      extra["errorState"] = stateName
    }
    emitEvent(type: "errorStateChanged", extra: extra)
  }

  public func didReceiveResult(_ result: [String]?) {
    emitEvent(type: "rpcResult", extra: ["rpcResult": result ?? []])
  }

  public func didReset() {
    knownDeviceIds.removeAll()
    emitEvent(type: "connectionStateChanged")
    emitEvent(type: "deviceStateChanged")
    emitEvent(type: "errorStateChanged")
    emitEvent(type: "rpcResult", extra: ["rpcResult": []])
    emitEvent(type: "scanningStateChanged", extra: ["isScanning": false])
  }

  public func didUpdateIsScanning(_ isScanning: Bool) {
    emitEvent(type: "scanningStateChanged", extra: ["isScanning": isScanning])
  }

  public func didFailScanningBluetoothNotAvailable() {
    emitEvent(type: "scanFailed", extra: ["reason": "bluetoothUnavailable"])
  }

  private func emitEvent(type: String, extra: [String: Any] = [:]) {
    var payload: [String: Any] = ["type": type]
    for (key, value) in extra {
      payload[key] = value
    }
    eventSink?(payload)
  }

  private func deviceMap(from peripheral: CBPeripheral) -> [String: Any] {
    return [
      "id": peripheral.identifier.uuidString,
      "name": peripheral.name ?? NSNull(),
    ]
  }

  private func mapBluetoothState(_ state: CBManagerState) -> String {
    switch state {
    case .unknown:
      return "unknown"
    case .resetting:
      return "resetting"
    case .unsupported:
      return "unsupported"
    case .unauthorized:
      return "unauthorized"
    case .poweredOff:
      return "poweredOff"
    case .poweredOn:
      return "poweredOn"
    @unknown default:
      return "unknown"
    }
  }

  private func mapDeviceState(_ state: DeviceState?) -> String? {
    switch state {
    case .authorizationRequired:
      return "authorizationRequired"
    case .authorized:
      return "authorized"
    case .provisioning:
      return "provisioning"
    case .provisioned:
      return "provisioned"
    case .none:
      return nil
    }
  }

  private func mapErrorState(_ state: ErrorState?) -> String? {
    switch state {
    case .noError:
      return "noError"
    case .invalidRPCPacket:
      return "invalidRpcPacket"
    case .unknownCommand:
      return "unknownCommand"
    case .unableToConnect:
      return "unableToConnect"
    case .notAuthorized:
      return "notAuthorized"
    case .unknown:
      return "unknown"
    case .none:
      return nil
    }
  }

  private func flutterError(from error: BluetoothManagerError) -> FlutterError {
    switch error {
    case .deviceDisconnected:
      return FlutterError(code: "not_connected", message: "No device is currently connected.", details: nil)
    case .serviceNotAvailable:
      return FlutterError(code: "service_not_available", message: "Improv service is not available on the connected device.", details: nil)
    }
  }
}
