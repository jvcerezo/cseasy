import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../premium/entitlement_controller.dart';

/// Set with --dart-define=ADMOB_BANNER_ID=ca-app-pub-xxx/yyy for release
/// builds. The default is Google's public test unit, which never pays out.
const _bannerUnitId = String.fromEnvironment(
  'ADMOB_BANNER_ID',
  defaultValue: 'ca-app-pub-3940256099942544/6300978111',
);

/// Gathers consent where the law requires it (Google's UMP flow), then
/// starts the Mobile Ads SDK. Never runs for users with full access.
final adsReadyProvider = FutureProvider<bool>((ref) async {
  if (ref.watch(isPremiumProvider)) return false;
  try {
    await _gatherConsent();
    if (!await ConsentInformation.instance.canRequestAds()) return false;
    await MobileAds.instance.initialize();
    return true;
  } catch (e) {
    debugPrint('[Ads] init failed: $e');
    return false;
  }
});

Future<void> _gatherConsent() {
  final done = Completer<void>();
  ConsentInformation.instance.requestConsentInfoUpdate(
    ConsentRequestParameters(),
    () => ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error != null) debugPrint('[Ads] consent form: ${error.message}');
      if (!done.isCompleted) done.complete();
    }),
    (error) {
      debugPrint('[Ads] consent update: ${error.message}');
      if (!done.isCompleted) done.complete();
    },
  );
  return done.future;
}

/// An adaptive banner for results screens. Renders nothing for paying users,
/// before consent/initialization, or if no ad loads.
class BannerAdSlot extends ConsumerStatefulWidget {
  const BannerAdSlot({super.key});

  @override
  ConsumerState<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends ConsumerState<BannerAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  Future<void> _load(int width) async {
    _requested = true;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
      Orientation.portrait,
      width,
    );
    if (size == null || !mounted) return;
    final ad = BannerAd(
      size: size,
      adUnitId: _bannerUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[Ads] banner failed: ${error.message}');
          ad.dispose();
          if (identical(_ad, ad)) _ad = null;
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(adsReadyProvider).valueOrNull ?? false;
    if (!ready || ref.watch(isPremiumProvider)) return const SizedBox.shrink();
    if (!_requested) {
      unawaited(_load(MediaQuery.sizeOf(context).width.truncate()));
    }
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
