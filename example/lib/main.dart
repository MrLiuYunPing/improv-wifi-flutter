import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:improv_wifi_flutter/improv_wifi_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _plugin = const ImprovWifiFlutter();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final List<ImprovWifiEvent> _events = <ImprovWifiEvent>[];
  final List<ImprovDevice> _devices = <ImprovDevice>[];
  StreamSubscription<ImprovWifiEvent>? _subscription;
  ImprovBluetoothState _bluetoothState = ImprovBluetoothState.unknown;
  ImprovDevice? _connectedDevice;
  ImprovDeviceState? _deviceState;
  ImprovErrorState? _errorState;
  List<String> _rpcResult = const <String>[];
  final List<List<String>> _rpcResultsHistory = <List<String>>[];
  Map<Permission, PermissionStatus> _permissionStatuses =
      <Permission, PermissionStatus>{};
  bool _isScanning = false;

  bool get _isIOS => Platform.isIOS;

  List<Permission> get _permissions {
    if (_isIOS) {
      return <Permission>[Permission.bluetooth];
    }

    return <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];
  }

  @override
  void initState() {
    super.initState();
    _subscription = _plugin.events.listen(_handleEvent);
    _loadBluetoothState();
    _loadPermissionStatuses();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadBluetoothState() async {
    try {
      final state = await _plugin.getBluetoothState();
      if (!mounted) {
        return;
      }
      setState(() {
        _bluetoothState = state;
      });
    } on PlatformException catch (error) {
      _pushMessage('Bluetooth state failed: ${error.message ?? error.code}');
    }
  }

  Future<void> _loadPermissionStatuses() async {
    if (_isIOS) {
      return;
    }

    final statuses = <Permission, PermissionStatus>{};
    for (final permission in _permissions) {
      statuses[permission] = await permission.status;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _permissionStatuses = statuses;
    });
  }

  void _handleEvent(ImprovWifiEvent event) {
    if (!mounted) {
      return;
    }
    setState(() {
      _events.insert(0, event);
      switch (event.type) {
        case ImprovWifiEventType.bluetoothStateChanged:
          _bluetoothState = event.bluetoothState ?? _bluetoothState;
          break;
        case ImprovWifiEventType.scanningStateChanged:
          _isScanning = event.isScanning ?? _isScanning;
          break;
        case ImprovWifiEventType.deviceFound:
          final device = event.device;
          if (device != null &&
              _devices.every((item) => item.id != device.id)) {
            _devices.add(device);
          }
          break;
        case ImprovWifiEventType.connectionStateChanged:
          _connectedDevice = event.device;
          break;
        case ImprovWifiEventType.deviceStateChanged:
          _deviceState = event.deviceState;
          break;
        case ImprovWifiEventType.errorStateChanged:
          _errorState = event.errorState;
          break;
        case ImprovWifiEventType.rpcResult:
          final result = List<String>.from(
            event.rpcResult ?? const <String>[],
          );
          _rpcResult = result;
          if (result.isNotEmpty) {
            _rpcResultsHistory.insert(0, result);
            if (_rpcResultsHistory.length > 10) {
              _rpcResultsHistory.removeLast();
            }
            _pushMessage('RPC result received: ${result.join(', ')}');
          } else {
            _pushMessage('RPC result received, but it was empty.');
          }
          break;
        case ImprovWifiEventType.scanFailed:
          _pushMessage('Scan failed: ${event.reason ?? 'unknown reason'}');
          break;
      }
    });
  }

  Future<void> _startScan() async {
    try {
      if (_isIOS) {
        setState(() {
          _devices.clear();
        });
        await _plugin.startScan();
        return;
      }

      await _loadPermissionStatuses();
      final granted = await _requestPermissions();
      if (!granted) {
        _pushMessage('Bluetooth permissions are required before scanning.');
        return;
      }
      setState(() {
        _devices.clear();
      });
      await _plugin.startScan();
    } on PlatformException catch (error) {
      _pushMessage('Start scan failed: ${error.message ?? error.code}');
    }
  }

  Future<bool> _requestPermissions() async {
    if (_isIOS) {
      try {
        await _plugin.startScan();
        return true;
      } on PlatformException catch (error) {
        _pushMessage('Bluetooth access failed: ${error.message ?? error.code}');
        return false;
      }
    }

    final statuses = await _permissions.request();

    await _loadBluetoothState();

    if (!mounted) {
      return false;
    }

    setState(() {
      _permissionStatuses = statuses;
    });

    return statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );
  }

  bool get _allPermissionsGranted {
    if (_isIOS) {
      return _bluetoothState == ImprovBluetoothState.poweredOn ||
          _bluetoothState == ImprovBluetoothState.poweredOff ||
          _bluetoothState == ImprovBluetoothState.resetting;
    }

    if (_permissionStatuses.length < _permissions.length) {
      return false;
    }
    return _permissionStatuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );
  }

  bool get _hasPermanentlyDeniedPermission {
    if (_isIOS) {
      return _bluetoothState == ImprovBluetoothState.unauthorized;
    }

    return _permissionStatuses.values.any(
      (status) => status.isPermanentlyDenied,
    );
  }

  Future<void> _stopScan() async {
    try {
      await _plugin.stopScan();
    } on PlatformException catch (error) {
      _pushMessage('Stop scan failed: ${error.message ?? error.code}');
    }
  }

  Future<void> _connect(ImprovDevice device) async {
    try {
      await _plugin.connectToDevice(device.id);
    } on PlatformException catch (error) {
      _pushMessage('Connect failed: ${error.message ?? error.code}');
    }
  }

  Future<void> _identify() async {
    try {
      await _plugin.identifyDevice();
    } on PlatformException catch (error) {
      _pushMessage('Identify failed: ${error.message ?? error.code}');
    }
  }

  Future<void> _sendWifi() async {
    try {
      await _plugin.sendWifi(
        ssid: _ssidController.text,
        password: _passwordController.text,
      );
    } on PlatformException catch (error) {
      _pushMessage('Send Wi-Fi failed: ${error.message ?? error.code}');
    }
  }

  void _pushMessage(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatRpcResult(List<String> result) {
    if (result.isEmpty) {
      return 'none';
    }
    return result.join('\n');
  }

  String _statusLabel(Permission permission) {
    final status = _permissionStatuses[permission];
    if (status == null) {
      return 'unknown';
    }
    if (status.isGranted) {
      return 'granted';
    }
    if (status.isDenied) {
      return 'denied';
    }
    if (status.isPermanentlyDenied) {
      return 'permanentlyDenied';
    }
    if (status.isRestricted) {
      return 'restricted';
    }
    if (status.isLimited) {
      return 'limited';
    }
    if (status.isProvisional) {
      return 'provisional';
    }
    return status.toString();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: Scaffold(
        appBar: AppBar(title: const Text('Improv Wi-Fi Demo')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Bluetooth: ${_bluetoothState.name}'),
                    Text('Scanning: $_isScanning'),
                    Text(
                      'Connected: ${_connectedDevice?.name ?? _connectedDevice?.id ?? 'none'}',
                    ),
                    Text('Device state: ${_deviceState?.name ?? 'none'}'),
                    Text('Error state: ${_errorState?.name ?? 'none'}'),
                    Text(
                      'Latest RPC result items: ${_rpcResult.length}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _loadBluetoothState,
                  child: const Text('Refresh State'),
                ),
                ElevatedButton(
                  onPressed: _startScan,
                  child: const Text('Start Scan'),
                ),
                ElevatedButton(
                  onPressed: _stopScan,
                  child: const Text('Stop Scan'),
                ),
                ElevatedButton(
                  onPressed: _identify,
                  child: const Text('Identify'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Bluetooth Access',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (_isIOS) ...<Widget>[
                      Text('bluetooth: ${_statusLabel(Permission.bluetooth)}'),
                      Text('coreBluetoothState: ${_bluetoothState.name}'),
                    ] else ...<Widget>[
                      Text(
                        'bluetoothScan: ${_statusLabel(Permission.bluetoothScan)}',
                      ),
                      Text(
                        'bluetoothConnect: ${_statusLabel(Permission.bluetoothConnect)}',
                      ),
                      Text(
                        'locationWhenInUse: ${_statusLabel(Permission.locationWhenInUse)}',
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (!_allPermissionsGranted)
                      ElevatedButton(
                        onPressed: () async {
                          final granted = await _requestPermissions();
                          if (!granted) {
                            _pushMessage(
                              _isIOS
                                  ? 'Start a scan to trigger the iOS Bluetooth prompt, or open Settings if previously denied.'
                                  : 'Some permissions are still denied.',
                            );
                          }
                        },
                        child: Text(
                          _isIOS
                              ? 'Trigger Bluetooth Prompt'
                              : 'Grant Permissions',
                        ),
                      ),
                    if (_hasPermanentlyDeniedPermission) ...<Widget>[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: openAppSettings,
                        child: const Text('Open App Settings'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ssidController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'SSID',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _sendWifi,
              child: const Text('Send Wi-Fi'),
            ),
            const SizedBox(height: 16),
            const Text(
              'RPC Result',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Latest result',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(_formatRpcResult(_rpcResult)),
                    if (_rpcResultsHistory.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      const Text(
                        'Recent results',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      for (final result in _rpcResultsHistory.take(5)) ...<
                        Widget
                      >[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(_formatRpcResult(result)),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Discovered devices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final device in _devices)
              Card(
                child: ListTile(
                  title: Text(device.name ?? 'Unnamed device'),
                  subtitle: Text(device.id),
                  trailing: ElevatedButton(
                    onPressed: () => _connect(device),
                    child: const Text('Connect'),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Event log',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final event in _events.take(20))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(event.type.name),
                subtitle: Text(
                  [
                    if (event.device != null) event.device!.id,
                    if (event.bluetoothState != null)
                      event.bluetoothState!.name,
                    if (event.deviceState != null) event.deviceState!.name,
                    if (event.errorState != null) event.errorState!.name,
                    if (event.reason != null) event.reason!,
                    if (event.rpcResult != null && event.rpcResult!.isNotEmpty)
                      event.rpcResult!.join(', '),
                  ].join(' | '),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
