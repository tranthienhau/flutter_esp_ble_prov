class Device {
  final String name;
  final String deviceId;
  final String macAddress;

  Device({
    required this.name,
    required this.deviceId,
    required this.macAddress,
  });

  factory Device.fromNativeString(String nativeString) {
    final parts = nativeString.split('_');
    if (parts.length >= 3) {
      final name = '${parts[0]}_${parts[1]}';
      final macAddress = parts[1];
      final deviceId = parts.sublist(2).join('_');
      return Device(name: name, deviceId: deviceId, macAddress: macAddress);
    }
    return Device(name: nativeString, deviceId: '', macAddress: '');
  }

  @override
  String toString() =>
      'Device(name: $name, deviceId: $deviceId, macAddress: $macAddress)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device &&
        other.name == name &&
        other.deviceId == deviceId &&
        other.macAddress == macAddress;
  }

  @override
  int get hashCode => name.hashCode ^ deviceId.hashCode ^ macAddress.hashCode;
}
