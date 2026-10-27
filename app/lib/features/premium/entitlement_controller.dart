import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../data/settings_providers.dart';
import 'premium_gate.dart';
import 'store.dart';

class Entitlement {
  final bool isPremium;
  final ProductDetails? product;
  final bool storeAvailable;

  /// A purchase is waiting on Google Play (dialog open or payment pending).
  final bool busy;

  /// User-facing outcome of the last action (error, pending notice).
  final String? message;

  const Entitlement({
    required this.isPremium,
    this.product,
    this.storeAvailable = false,
    this.busy = false,
    this.message,
  });

  Entitlement copyWith({
    bool? isPremium,
    ProductDetails? product,
    bool? storeAvailable,
    bool? busy,
    String? message,
  }) =>
      Entitlement(
        isPremium: isPremium ?? this.isPremium,
        product: product ?? this.product,
        storeAvailable: storeAvailable ?? this.storeAvailable,
        busy: busy ?? this.busy,
        message: message,
      );
}

final storeProvider = Provider<Store>((ref) => PlayStore());

final entitlementProvider = NotifierProvider<EntitlementController, Entitlement>(
  EntitlementController.new,
);

/// True when the user has the one-time full-access unlock.
final isPremiumProvider = Provider<bool>((ref) => ref.watch(entitlementProvider).isPremium);

const _premiumKey = 'has_full_access';

/// Owns the full-access unlock. The flag is cached locally so a paying user
/// keeps access offline; Play's restore flow re-grants it on reinstall.
class EntitlementController extends Notifier<Entitlement> {
  StreamSubscription<List<PurchaseDetails>>? _sub;

  @override
  Entitlement build() {
    final cached = ref.watch(sharedPreferencesProvider).getBool(_premiumKey) ?? false;
    ref.onDispose(() => _sub?.cancel());
    // Store setup is async; state starts from the cache and updates after.
    Future.microtask(_connect);
    return Entitlement(isPremium: cached);
  }

  Store get _store => ref.read(storeProvider);

  Future<void> _connect() async {
    try {
      _sub = _store.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) => debugPrint('[Billing] purchase stream error: $e'),
      );
      final available = await _store.isAvailable();
      if (!available) {
        state = state.copyWith(storeAvailable: false);
        return;
      }
      final product = await _store.queryProduct(fullAccessProductId);
      state = state.copyWith(storeAvailable: true, product: product);
      // Re-grants the unlock after a reinstall or on a new device.
      await _store.restorePurchases();
    } catch (e) {
      debugPrint('[Billing] setup failed: $e');
      state = state.copyWith(storeAvailable: false);
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != fullAccessProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(busy: true, message: 'Payment pending. Access unlocks once it clears.');
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          await _grant();
        case PurchaseStatus.error:
          state = state.copyWith(busy: false, message: purchase.error?.message ?? 'Purchase failed.');
        case PurchaseStatus.canceled:
          state = state.copyWith(busy: false);
      }
      // Unacknowledged Play purchases are refunded after 3 days.
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
  }

  Future<void> _grant() async {
    state = state.copyWith(isPremium: true, busy: false);
    await ref.read(sharedPreferencesProvider).setBool(_premiumKey, true);
  }

  Future<void> buy() async {
    final product = state.product;
    if (product == null) {
      state = state.copyWith(message: 'The store is unavailable right now. Please try again later.');
      return;
    }
    state = state.copyWith(busy: true);
    try {
      final started = await _store.buyNonConsumable(product);
      if (!started) state = state.copyWith(busy: false, message: 'Could not start the purchase.');
    } catch (e) {
      state = state.copyWith(busy: false, message: 'Could not start the purchase.');
      debugPrint('[Billing] buy failed: $e');
    }
  }

  Future<void> restore() async {
    try {
      await _store.restorePurchases();
      if (!state.isPremium) {
        state = state.copyWith(
          message: 'If you bought full access with this Google account, it will unlock shortly.',
        );
      }
    } catch (e) {
      state = state.copyWith(message: 'Could not reach Google Play.');
      debugPrint('[Billing] restore failed: $e');
    }
  }

  void clearMessage() => state = state.copyWith();
}
