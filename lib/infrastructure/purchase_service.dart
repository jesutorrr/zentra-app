/// Purchase boundary kept for a future, properly configured tip jar.
///
/// Monetization is intentionally unavailable in 1.0.20. Keeping this local
/// implementation prevents an unconfigured third-party SDK and fake store
/// prices from shipping in the release binary.
class PurchaseService {
  static final PurchaseService _instance = PurchaseService._();

  factory PurchaseService() => _instance;

  PurchaseService._();

  bool get isInitialized => false;

  Future<void> initialize() async {}

  Future<void> setUserId(String userId) async {}

  Future<List<TipProduct>> getAvailableTips() async => const [];

  Future<PurchaseResult> purchaseTip(TipProduct tip) async {
    return const PurchaseResult(
      success: false,
      message: 'Compras no disponibles en esta versión',
    );
  }

  Future<bool> isSupporter() async => false;

  Future<PurchaseResult> restorePurchases() async {
    return const PurchaseResult(
      success: false,
      message: 'Compras no disponibles en esta versión',
    );
  }
}

class TipProduct {
  final String id;
  final String title;
  final String description;
  final String priceString;

  const TipProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.priceString,
  });
}

class PurchaseResult {
  final bool success;
  final bool isSupporter;
  final String message;

  const PurchaseResult({
    required this.success,
    required this.message,
    this.isSupporter = false,
  });
}
