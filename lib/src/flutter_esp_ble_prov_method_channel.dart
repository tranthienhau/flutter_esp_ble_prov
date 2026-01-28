import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'device.dart';
import 'flutter_esp_ble_prov_platform_interface.dart';

/// An implementation of [FlutterEspBleProvPlatform] that uses method channels.
class MethodChannelFlutterEspBleProv extends FlutterEspBleProvPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_esp_ble_prov');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<List<Device>> scanBleDevices(String prefix) async {
    final args = {'prefix': prefix};
    final raw =
        await methodChannel.invokeMethod<List<Object?>>('scanBleDevices', args);
    if (raw == null) return [];
    return raw.cast<String>().map((e) => Device.fromNativeString(e)).toList();
  }

  @override
  Future<List<String>> scanWifiNetworks(
      String deviceName, String proofOfPossession) async {
    final args = {
      'deviceName': deviceName,
      'proofOfPossession': proofOfPossession,
    };
    final raw = await methodChannel.invokeMethod<List<Object?>>(
        'scanWifiNetworks', args);
    final List<String> networks = [];
    if (raw != null) {
      networks.addAll(raw.cast<String>());
    }
    return networks;
  }

  @override
  Future<bool?> provisionWifi(String deviceName, String proofOfPossession,
      String ssid, String passphrase) async {
    final args = {
      'deviceName': deviceName,
      'proofOfPossession': proofOfPossession,
      'ssid': ssid,
      'passphrase': passphrase
    };
    return await methodChannel.invokeMethod<bool?>('provisionWifi', args);
  }
}
