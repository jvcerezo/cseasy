import 'dart:async';

import 'package:cseasy/core/content/question.dart';
import 'package:cseasy/core/content/question_bank.dart';
import 'package:cseasy/data/settings_providers.dart';
import 'package:cseasy/features/premium/entitlement_controller.dart';
import 'package:cseasy/features/premium/premium_gate.dart';
import 'package:cseasy/features/premium/store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

Question _q(String id, String topic) => Question(
      id: id,
      levels: const {'professional'},
      section: Section.numerical,
      topic: topic,
      stem: id,
      choices: const ['a', 'b', 'c', 'd'],
      answer: 0,
      explanation: 'e',
      source: null,
      difficulty: 1,
    );

class _FakeStore implements Store {
  final purchases = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <PurchaseDetails>[];
  bool available = true;
  int restores = 0;

  static final product = ProductDetails(
    id: fullAccessProductId,
    title: 'Full access',
    description: '',
    price: '₱199.00',
    rawPrice: 199,
    currencyCode: 'PHP',
  );

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => purchases.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetails?> queryProduct(String id) async => id == fullAccessProductId ? product : null;

  @override
  Future<bool> buyNonConsumable(ProductDetails product) async => true;

  @override
  Future<void> restorePurchases() async => restores++;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async => completed.add(purchase);
}

PurchaseDetails _purchase(PurchaseStatus status) => PurchaseDetails(
      productID: fullAccessProductId,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'google_play',
      ),
      transactionDate: '0',
      status: status,
    )..pendingCompletePurchase = true;

Future<ProviderContainer> _container(_FakeStore store, {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
    storeProvider.overrideWithValue(store),
  ]);
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('freeTier', () {
    test('keeps the first N items of each topic by id', () {
      final bank = QuestionBank('v', [
        for (var i = 0; i < 25; i++) _q('pct-${i.toString().padLeft(3, '0')}', 'percentage'),
        for (var i = 0; i < 4; i++) _q('age-$i', 'age'),
      ]);
      final free = freeTier(bank);
      expect(free.byTopic('percentage'), hasLength(freeQuestionsPerTopic));
      expect(free.byTopic('percentage').map((q) => q.id), contains('pct-000'));
      expect(free.byTopic('percentage').map((q) => q.id), isNot(contains('pct-024')));
      expect(free.byTopic('age'), hasLength(4));
    });

    test('full mocks: one free, unlimited with full access', () {
      expect(canStartFullMock(isPremium: false, fullMocksTaken: 0), isTrue);
      expect(canStartFullMock(isPremium: false, fullMocksTaken: 1), isFalse);
      expect(canStartFullMock(isPremium: true, fullMocksTaken: 9), isTrue);
    });
  });

  group('EntitlementController', () {
    test('connects, loads the product and restores past purchases', () async {
      final store = _FakeStore();
      final container = await _container(store);
      expect(container.read(entitlementProvider).isPremium, isFalse);
      await _settle();
      final state = container.read(entitlementProvider);
      expect(state.storeAvailable, isTrue);
      expect(state.product?.price, '₱199.00');
      expect(store.restores, 1);
    });

    test('a completed purchase grants access, persists it, and is acknowledged', () async {
      final store = _FakeStore();
      final container = await _container(store);
      container.read(entitlementProvider);
      await _settle();

      final purchase = _purchase(PurchaseStatus.purchased);
      store.purchases.add([purchase]);
      await _settle();

      expect(container.read(isPremiumProvider), isTrue);
      expect((await SharedPreferences.getInstance()).getBool('has_full_access'), isTrue);
      expect(store.completed, [purchase]);
    });

    test('cached access survives an offline start', () async {
      final store = _FakeStore()..available = false;
      final container = await _container(store, prefs: {'has_full_access': true});
      await _settle();
      expect(container.read(isPremiumProvider), isTrue);
    });

    test('a failed purchase does not grant access', () async {
      final store = _FakeStore();
      final container = await _container(store);
      container.read(entitlementProvider);
      await _settle();

      store.purchases.add([_purchase(PurchaseStatus.error)]);
      await _settle();
      expect(container.read(isPremiumProvider), isFalse);
      expect(container.read(entitlementProvider).busy, isFalse);
    });
  });
}
