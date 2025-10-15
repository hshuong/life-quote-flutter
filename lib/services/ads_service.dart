// lib/services/ads_service.dart

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

class AdsService {
  static final AdsService _instance = AdsService._internal();

  factory AdsService() {
    return _instance;
  }

  AdsService._internal();

  // Test Ad Unit IDs (from Google - use real IDs in production)
  static const String bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String nativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';

  // Initialize Mobile Ads SDK
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // Load Banner Ad
  Future<BannerAd?> loadBannerAd() async {
    try {
      final BannerAd bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            print('✓ Banner ad loaded');
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            print('✗ Banner ad failed to load: $error');
            ad.dispose();
          },
          onAdOpened: (Ad ad) {
            print('Banner ad opened');
          },
          onAdClosed: (Ad ad) {
            print('Banner ad closed');
          },
        ),
      );

      await bannerAd.load();
      return bannerAd;
    } catch (e) {
      print('Error loading banner ad: $e');
      return null;
    }
  }

  // Load Interstitial Ad
Future<InterstitialAd?> loadInterstitialAd() async {
  final completer = Completer<InterstitialAd?>();

  InterstitialAd.load(
    adUnitId: interstitialAdUnitId,
    request: const AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (InterstitialAd ad) {
        print('✓ Interstitial ad loaded');
        completer.complete(ad);
      },
      onAdFailedToLoad: (LoadAdError error) {
        print('✗ Interstitial ad failed to load: $error');
        completer.complete(null);
      },
    ),
  );

  return completer.future;
}

  // Load Native Ad
  Future<NativeAd?> loadNativeAd() async {
    try {
      final NativeAd nativeAd = NativeAd(
        adUnitId: nativeAdUnitId,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (Ad ad) {
            print('✓ Native ad loaded');
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            print('✗ Native ad failed to load: $error');
            ad.dispose();
          },
          onAdOpened: (Ad ad) {
            print('Native ad opened');
          },
          onAdClosed: (Ad ad) {
            print('Native ad closed');
          },
        ),
        nativeAdOptions: NativeAdOptions(
          adChoicesPlacement: AdChoicesPlacement.bottomLeftCorner,
        ),
      );

      await nativeAd.load();
      return nativeAd;
    } catch (e) {
      print('Error loading native ad: $e');
      return null;
    }
  }

  // Show Interstitial Ad
  void showInterstitialAd(InterstitialAd? ad) {
    if (ad != null) {
      ad.show();
    }
  }
}