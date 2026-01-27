/// Error codes for ESP BLE Provisioning plugin
///
/// These error codes are standardized across iOS and Android platforms.
/// The native layer provides accurate error descriptions that should be used directly.
class EspBleProvError {
  // Error codes
  static const String bleScanFailed = 'BLE_SCAN_FAILED';
  static const String deviceNotFound = 'DEVICE_NOT_FOUND';
  static const String connectionFailed = 'CONNECTION_FAILED';
  static const String authFailed = 'AUTH_FAILED';
  static const String wifiScanFailed = 'WIFI_SCAN_FAILED';
  static const String provisionFailed = 'PROVISION_FAILED';
  static const String deviceDisconnected = 'DEVICE_DISCONNECTED';
  static const String unknownError = 'UNKNOWN_ERROR';
}
