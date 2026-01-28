class Device {
  final String name;
  final String deviceId;

  Device({
    required this.name,
    required this.deviceId,
  });

  factory Device.fromNativeString(String nativeString) {
    final parts = nativeString.split('_');
    if (parts.length >= 3) {
      final name = '${parts[0]}_${parts[1]}';
      final deviceId = parts.sublist(2).join('_');
      return Device(name: name, deviceId: deviceId);
    }
    return Device(name: nativeString, deviceId: '');
  }

  @override
  String toString() => 'Device(name: $name, deviceId: $deviceId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device && other.name == name && other.deviceId == deviceId;
  }

  @override
  int get hashCode => name.hashCode ^ deviceId.hashCode;
}
