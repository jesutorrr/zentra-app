class CloudLinkPreview {
  final String sourceOwnerId;
  final Map<String, int> counts;
  final String checksum;

  CloudLinkPreview({
    required this.sourceOwnerId,
    required Map<String, int> counts,
    required this.checksum,
  }) : counts = Map.unmodifiable(counts);

  int get totalRecords => counts.values.fold(0, (sum, count) => sum + count);
}

class CloudLinkResult {
  final String sourceOwnerId;
  final String remoteOwnerId;
  final Map<String, int> sourceCounts;
  final Map<String, int> targetCounts;
  final String sourceChecksum;
  final String targetChecksum;
  final bool remoteWasEmpty;

  CloudLinkResult({
    required this.sourceOwnerId,
    required this.remoteOwnerId,
    required Map<String, int> sourceCounts,
    required Map<String, int> targetCounts,
    required this.sourceChecksum,
    required this.targetChecksum,
    required this.remoteWasEmpty,
  })  : sourceCounts = Map.unmodifiable(sourceCounts),
        targetCounts = Map.unmodifiable(targetCounts);
}
