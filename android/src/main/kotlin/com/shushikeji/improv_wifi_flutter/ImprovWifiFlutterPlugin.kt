package com.shushikeji.improv_wifi_flutter

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.wifi.improv.DeviceState
import com.wifi.improv.ErrorState
import com.wifi.improv.ImprovDevice
import com.wifi.improv.ImprovManager
import com.wifi.improv.ImprovManagerCallback
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class ImprovWifiFlutterPlugin :
    FlutterPlugin,
    MethodCallHandler,
    EventChannel.StreamHandler,
    ImprovManagerCallback {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var applicationContext: Context
    private lateinit var improvManager: ImprovManager
    private lateinit var bluetoothManager: BluetoothManager
    private val discoveredDevices = mutableMapOf<String, ImprovDevice>()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var bluetoothStateReceiver: BroadcastReceiver? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        bluetoothManager =
            applicationContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        improvManager = ImprovManager(applicationContext, this)
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "improv_wifi_flutter")
        eventChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "improv_wifi_flutter/events")
        channel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        registerBluetoothStateReceiver()
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "getBluetoothState" -> result.success(getBluetoothStateName())
            "startScan" -> {
                if (getBluetoothStateName() != "poweredOn") {
                    emitEvent(
                        mapOf(
                            "type" to "scanFailed",
                            "reason" to "bluetoothUnavailable"
                        )
                    )
                    result.error(
                        "bluetooth_unavailable",
                        "Bluetooth must be powered on before scanning.",
                        null
                    )
                    return
                }
                improvManager.findDevices()
                result.success(null)
            }
            "stopScan" -> {
                improvManager.stopScan()
                result.success(null)
            }
            "connectToDevice" -> {
                val deviceId = call.argument<String>("deviceId")
                if (deviceId.isNullOrBlank()) {
                    result.error("invalid_argument", "deviceId is required.", null)
                    return
                }
                val device = discoveredDevices[deviceId]
                if (device == null) {
                    result.error(
                        "device_not_found",
                        "Device $deviceId must be discovered before connecting.",
                        null
                    )
                    return
                }
                improvManager.connectToDevice(device)
                result.success(null)
            }
            "identifyDevice" -> {
                try {
                    improvManager.identifyDevice()
                    result.success(null)
                } catch (exception: IllegalStateException) {
                    result.error("not_connected", exception.message, null)
                }
            }
            "sendWifi" -> {
                val ssid = call.argument<String>("ssid")
                val password = call.argument<String>("password")
                if (ssid == null || password == null) {
                    result.error("invalid_argument", "ssid and password are required.", null)
                    return
                }
                try {
                    improvManager.sendWifi(ssid, password)
                    result.success(null)
                } catch (exception: IllegalStateException) {
                    result.error("not_connected", exception.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink
    ) {
        eventSink = events
        emitEvent(
            mapOf(
                "type" to "bluetoothStateChanged",
                "bluetoothState" to getBluetoothStateName()
            )
        )
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onScanningStateChange(scanning: Boolean) {
        emitEvent(
            mapOf(
                "type" to "scanningStateChanged",
                "isScanning" to scanning
            )
        )
    }

    override fun onDeviceFound(device: ImprovDevice) {
        discoveredDevices[device.address] = device
        emitEvent(
            mapOf(
                "type" to "deviceFound",
                "device" to device.toMap()
            )
        )
    }

    override fun onConnectionStateChange(device: ImprovDevice?) {
        emitEvent(
            mapOf(
                "type" to "connectionStateChanged",
                "device" to device?.toMap()
            )
        )
    }

    override fun onStateChange(state: DeviceState) {
        emitEvent(
            mapOf(
                "type" to "deviceStateChanged",
                "deviceState" to state.toFlutterName()
            )
        )
    }

    override fun onErrorStateChange(errorState: ErrorState) {
        emitEvent(
            mapOf(
                "type" to "errorStateChanged",
                "errorState" to errorState.toFlutterName()
            )
        )
    }

    override fun onRpcResult(result: List<String>) {
        emitEvent(
            mapOf(
                "type" to "rpcResult",
                "rpcResult" to result
            )
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        unregisterBluetoothStateReceiver()
    }

    private fun registerBluetoothStateReceiver() {
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(
                context: Context?,
                intent: Intent?
            ) {
                if (intent?.action == BluetoothAdapter.ACTION_STATE_CHANGED) {
                    emitEvent(
                        mapOf(
                            "type" to "bluetoothStateChanged",
                            "bluetoothState" to getBluetoothStateName()
                        )
                    )
                }
            }
        }
        bluetoothStateReceiver = receiver

        val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            applicationContext.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            applicationContext.registerReceiver(receiver, filter)
        }
    }

    private fun unregisterBluetoothStateReceiver() {
        bluetoothStateReceiver?.let {
            applicationContext.unregisterReceiver(it)
        }
        bluetoothStateReceiver = null
    }

    private fun getBluetoothStateName(): String {
        val adapter = bluetoothManager.adapter ?: return "unsupported"
        return when (adapter.state) {
            BluetoothAdapter.STATE_ON -> "poweredOn"
            BluetoothAdapter.STATE_OFF -> "poweredOff"
            BluetoothAdapter.STATE_TURNING_ON,
            BluetoothAdapter.STATE_TURNING_OFF -> "resetting"
            else -> "unknown"
        }
    }

    private fun emitEvent(event: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(event)
        }
    }

    private fun ImprovDevice.toMap(): Map<String, Any?> {
        return mapOf(
            "id" to address,
            "name" to name
        )
    }

    private fun DeviceState.toFlutterName(): String {
        return when (this) {
            DeviceState.AUTHORIZATION_REQUIRED -> "authorizationRequired"
            DeviceState.AUTHORIZED -> "authorized"
            DeviceState.PROVISIONING -> "provisioning"
            DeviceState.PROVISIONED -> "provisioned"
        }
    }

    private fun ErrorState.toFlutterName(): String {
        return when (this) {
            ErrorState.NO_ERROR -> "noError"
            ErrorState.INVALID_RPC_PACKET -> "invalidRpcPacket"
            ErrorState.UNKNOWN_COMMAND -> "unknownCommand"
            ErrorState.UNABLE_TO_CONNECT -> "unableToConnect"
            ErrorState.NOT_AUTHORIZED -> "notAuthorized"
            ErrorState.UNKNOWN -> "unknown"
        }
    }
}
