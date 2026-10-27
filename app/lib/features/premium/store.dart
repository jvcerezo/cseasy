import 'package:in_app_purchase/in_app_purchase.dart';

/// The slice of the billing API the app uses, so purchase logic can be
/// tested without Google Play.
abstract interface class Store {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<ProductDetails?> queryProduct(String id);
  Future<bool> buyNonConsumable(ProductDetails product);
  Future<void> restorePurchases();
  Future<void> completePurchase(PurchaseDetails purchase);
}

class PlayStore implements Store {
  final InAppPurchase _iap;

  PlayStore([InAppPurchase? iap]) : _iap = iap ?? InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<ProductDetails?> queryProduct(String id) async {
    final response = await _iap.queryProductDetails({id});
    return response.productDetails.where((p) => p.id == id).firstOrNull;
  }

  @override
  Future<bool> buyNonConsumable(ProductDetails product) =>
      _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));

  @override
  Future<void> restorePurchases() => _iap.restorePurchases();

  @override
  Future<void> completePurchase(PurchaseDetails purchase) => _iap.completePurchase(purchase);
}
