import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import 'entitlement_controller.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementProvider);
    final controller = ref.read(entitlementProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    ref.listen(entitlementProvider.select((e) => e.message), (_, message) {
      if (message == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      controller.clearMessage();
    });

    final product = entitlement.product;
    final unavailable = entitlement.storeChecked && product == null;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.workspace_premium, size: 56, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              entitlement.isPremium ? Strings.youHaveFullAccess : Strings.unlockTitle,
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            for (final benefit in const [
              Strings.unlockBenefitAll,
              Strings.unlockBenefitMocks,
              Strings.unlockBenefitAds,
              Strings.unlockBenefitOnce,
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(benefit, style: textTheme.bodyLarge)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            if (!entitlement.isPremium) ...[
              FilledButton(
                onPressed: product == null || entitlement.busy ? null : controller.buy,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: entitlement.busy
                    ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(switch (product) {
                        final p? => Strings.unlockCta(p.price),
                        null => unavailable ? Strings.unavailable : Strings.priceLoading,
                      }),
              ),
              if (unavailable) ...[
                const SizedBox(height: 8),
                Text(Strings.storeUnavailable, style: textTheme.bodySmall, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 8),
              TextButton(onPressed: controller.restore, child: const Text(Strings.restorePurchase)),
            ],
          ],
        ),
      ),
    );
  }
}
