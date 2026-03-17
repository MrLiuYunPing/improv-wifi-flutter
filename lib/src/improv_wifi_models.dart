class ImprovDevice {
  const ImprovDevice({required this.id, this.name});

  final String id;
  final String? name;

  factory ImprovDevice.fromMap(Map<Object?, Object?> map) {
    return ImprovDevice(
      id: map['id'] as String? ?? '',
      name: map['name'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{'id': id, 'name': name};
  }
}

enum ImprovBluetoothState {
  unknown,
  resetting,
  unsupported,
  unauthorized,
  poweredOff,
  poweredOn;

  static ImprovBluetoothState fromName(String? value) {
    for (final item in values) {
      if (item.name == value) {
        return item;
      }
    }
    return ImprovBluetoothState.unknown;
  }
}

enum ImprovDeviceState {
  authorizationRequired,
  authorized,
  provisioning,
  provisioned;

  static ImprovDeviceState? fromName(String? value) {
    for (final item in values) {
      if (item.name == value) {
        return item;
      }
    }
    return null;
  }
}

enum ImprovErrorState {
  noError,
  invalidRpcPacket,
  unknownCommand,
  unableToConnect,
  notAuthorized,
  unknown;

  static ImprovErrorState? fromName(String? value) {
    for (final item in values) {
      if (item.name == value) {
        return item;
      }
    }
    return null;
  }
}

enum ImprovWifiEventType {
  bluetoothStateChanged,
  scanningStateChanged,
  deviceFound,
  connectionStateChanged,
  deviceStateChanged,
  errorStateChanged,
  rpcResult,
  scanFailed;

  static ImprovWifiEventType fromName(String? value) {
    for (final item in values) {
      if (item.name == value) {
        return item;
      }
    }
    return ImprovWifiEventType.scanFailed;
  }
}

class ImprovWifiEvent {
  const ImprovWifiEvent({
    required this.type,
    this.device,
    this.bluetoothState,
    this.isScanning,
    this.deviceState,
    this.errorState,
    this.rpcResult,
    this.reason,
  });

  final ImprovWifiEventType type;
  final ImprovDevice? device;
  final ImprovBluetoothState? bluetoothState;
  final bool? isScanning;
  final ImprovDeviceState? deviceState;
  final ImprovErrorState? errorState;
  final List<String>? rpcResult;
  final String? reason;

  factory ImprovWifiEvent.fromMap(Map<Object?, Object?> map) {
    final rawDevice = map['device'];
    final rawResult = map['rpcResult'];

    return ImprovWifiEvent(
      type: ImprovWifiEventType.fromName(map['type'] as String?),
      device: rawDevice is Map<Object?, Object?>
          ? ImprovDevice.fromMap(rawDevice)
          : null,
      bluetoothState: map.containsKey('bluetoothState')
          ? ImprovBluetoothState.fromName(map['bluetoothState'] as String?)
          : null,
      isScanning: map['isScanning'] as bool?,
      deviceState: ImprovDeviceState.fromName(map['deviceState'] as String?),
      errorState: ImprovErrorState.fromName(map['errorState'] as String?),
      rpcResult: rawResult is List<Object?>
          ? rawResult
                .map((Object? item) => item.toString())
                .toList(growable: false)
          : null,
      reason: map['reason'] as String?,
    );
  }
}
