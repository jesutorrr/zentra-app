class CloudRuntimePolicy {
  static const dartDefineName = 'ZENTRA_CLOUD_ENABLED';

  static const current = CloudRuntimePolicy(
    enabled: bool.fromEnvironment(
      dartDefineName,
      defaultValue: false,
    ),
  );

  static const parked = CloudRuntimePolicy(enabled: false);
  static const active = CloudRuntimePolicy(enabled: true);

  final bool enabled;

  const CloudRuntimePolicy({required this.enabled});

  factory CloudRuntimePolicy.fromDartDefines() => current;

  bool get isParked => !enabled;
}
