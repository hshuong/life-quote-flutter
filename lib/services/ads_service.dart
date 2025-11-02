// lib/services/ads_service.dart

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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

  // Load Banner Ad (Standard)
  Future<BannerAd?> loadBannerAd() async {
    try {
      final BannerAd bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            debugPrint('✓ Banner ad loaded');
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            debugPrint('✗ Banner ad failed to load: $error');
            ad.dispose();
          },
          onAdOpened: (Ad ad) {
            debugPrint('Banner ad opened');
          },
          onAdClosed: (Ad ad) {
            debugPrint('Banner ad closed');
          },
        ),
      );

      await bannerAd.load();
      return bannerAd;
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
      return null;
    }
  }

  // Load Adaptive Banner Ad (NEW)
  Future<BannerAd?> loadAdaptiveBannerAd(AdSize size) async {
    try {
      final BannerAd bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        request: const AdRequest(),
        size: size,  // Use adaptive size
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            debugPrint('✓ Adaptive Banner ad loaded (${size.width}x${size.height})');
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            debugPrint('✗ Adaptive Banner ad failed to load: $error');
            ad.dispose();
          },
          onAdOpened: (Ad ad) {
            debugPrint('Adaptive Banner ad opened');
          },
          onAdClosed: (Ad ad) {
            debugPrint('Adaptive Banner ad closed');
          },
        ),
      );

      await bannerAd.load();
      return bannerAd;
    } catch (e) {
      debugPrint('Error loading adaptive banner ad: $e');
      return null;
    }
  }

  // Helper: Get Adaptive Banner Size for current screen width
  Future<AdSize?> getAdaptiveBannerSize(int screenWidth) async {
    try {
      final AdSize? size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        screenWidth,
      );
      
      if (size == null) {
        debugPrint('Unable to get adaptive banner size');
        return null;
      }

      debugPrint('Adaptive banner size: ${size.width}x${size.height}');
      return size;
    } catch (e) {
      debugPrint('Error getting adaptive banner size: $e');
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
          debugPrint('✓ Interstitial ad loaded');
          completer.complete(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('✗ Interstitial ad failed to load: $error');
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
            debugPrint('✓ Native ad loaded');
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            debugPrint('✗ Native ad failed to load: $error');
            ad.dispose();
          },
          onAdOpened: (Ad ad) {
            debugPrint('Native ad opened');
          },
          onAdClosed: (Ad ad) {
            debugPrint('Native ad closed');
          },
        ),
        nativeAdOptions: NativeAdOptions(
          adChoicesPlacement: AdChoicesPlacement.bottomLeftCorner,
        ),
      );

      await nativeAd.load();
      return nativeAd;
    } catch (e) {
      debugPrint('Error loading native ad: $e');
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