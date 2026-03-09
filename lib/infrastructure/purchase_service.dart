import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'app_logger.dart';

/// RevenueCat purchase service for tip jar and premium features.
///
/// Configure your RevenueCat API keys before using:
/// - iOS: App Store Connect + RevenueCat dashboard
/// - Android: Google Play Console + RevenueCat dashboard
class PurchaseService {
  static final PurchaseService _instance = PurchaseService._();
  factory PurchaseService() => _instance;
  PurchaseService._();

  static const _iosApiKey = 'appl_YOUR_REVENUECAT_IOS_KEY';
  static const _androidApiKey = 'goog_YOUR_REVENUECAT_ANDROID_KEY';

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize RevenueCat SDK. Call once at app startup.
  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    try {
      final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;

      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      _initialized = true;
      AppLogger().info('PurchaseService', 'Initialized');
    } catch (e) {
      AppLogger().error('PurchaseService', 'Init failed: $e');
    }
  }

  /// Set the RevenueCat user ID for attribution.
  Future<void> setUserId(String userId) async {
    if (!_initialized) return;
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      AppLogger().error('PurchaseService', 'setUserId failed: $e');
    }
  }

  /// Get available tip jar offerings.
  Future<List<TipProduct>> getAvailableTips() async {
    if (!_initialized) return _fallbackTips();

    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current == null || current.availablePackages.isEmpty) {
        return _fallbackTips();
      }

      return current.availablePackages.map((pkg) {
        return TipProduct(
          id: pkg.storeProduct.identifier,
          title: pkg.storeProduct.title,
          description: pkg.storeProduct.description,
          priceString: pkg.storeProduct.priceString,
          package: pkg,
        );
      }).toList();
    } catch (e) {
      AppLogger().error('PurchaseService', 'Failed to fetch offerings: $e');
      return _fallbackTips();
    }
  }

  /// Purchase a tip.
  Future<PurchaseResult> purchaseTip(TipProduct tip) async {
    if (!_initialized || tip.package == null) {
      return PurchaseResult(
        success: false,
        message: 'Compras no disponibles en este momento',
      );
    }

    try {
      final result = await Purchases.purchasePackage(tip.package!);
      final isActive = result.entitlements.all['supporter']?.isActive ?? false;

      return PurchaseResult(
        success: true,
        isSupporter: isActive,
        message: '¡Gracias por tu apoyo!',
      );
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult(success: false, message: 'Compra cancelada');
      }
      AppLogger().error('PurchaseService', 'PlatformException: $errorCode - ${e.message}');
      return PurchaseResult(success: false, message: 'Error en la compra');
    } catch (e) {
      AppLogger().error('PurchaseService', 'Purchase failed: $e');
      return PurchaseResult(success: false, message: 'Error inesperado');
    }
  }

  /// Check if user is a supporter.
  Future<bool> isSupporter() async {
    if (!_initialized) return false;

    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.all['supporter']?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Restore previous purchases.
  Future<PurchaseResult> restorePurchases() async {
    if (!_initialized) {
      return PurchaseResult(
        success: false,
        message: 'Compras no disponibles',
      );
    }

    try {
      final info = await Purchases.restorePurchases();
      final isActive = info.entitlements.all['supporter']?.isActive ?? false;

      return PurchaseResult(
        success: true,
        isSupporter: isActive,
        message: isActive
            ? '¡Compras restauradas! Eres Supporter'
            : 'No se encontraron compras previas',
      );
    } catch (e) {
      AppLogger().error('PurchaseService', 'Restore failed: $e');
      return PurchaseResult(
        success: false,
        message: 'Error al restaurar compras',
      );
    }
  }

  List<TipProduct> _fallbackTips() => [
        TipProduct(
          id: 'zentra_tip_coffee',
          title: 'Un cafecito',
          description: 'Para las noches de código',
          priceString: '\$0.99',
        ),
        TipProduct(
          id: 'zentra_tip_tacos',
          title: 'Unos tacos',
          description: 'Combustible mexicano',
          priceString: '\$2.99',
        ),
        TipProduct(
          id: 'zentra_tip_mega',
          title: 'Mega apoyo',
          description: 'Eres increíble',
          priceString: '\$9.99',
        ),
      ];
}

class TipProduct {
  final String id;
  final String title;
  final String description;
  final String priceString;
  final Package? package;

  const TipProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.priceString,
    this.package,
  });
}

class PurchaseResult {
  final bool success;
  final bool isSupporter;
  final String message;

  const PurchaseResult({
    required this.success,
    this.isSupporter = false,
    required this.message,
  });
}
