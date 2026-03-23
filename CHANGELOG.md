## 0.0.3

* Keep discovered iOS peripherals when stopping a scan so users can still connect after scan stops.

## 0.0.2

* Improved RPC result handling for fragmented BLE responses across iOS and Android.
* Fixed iOS BLE operation queue progression for connect and characteristic read callbacks.
* Updated the example app to show the latest RPC result and recent result history.

## 0.0.1

* Initial Flutter plugin release for Android and iOS.
* Vendored the native improv-wifi sources directly into the plugin.
* Added cross-platform scanning, connect, identify, Wi-Fi provisioning, and event APIs.
* Added fragmented RPC result parsing for devices that return results across multiple BLE notifications.
