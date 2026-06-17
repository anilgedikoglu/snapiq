import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// AdService — Google AdMob interstitial integration.
///
/// AdMob App IDs (set in AndroidManifest.xml / Info.plist):
///   Android: ca-app-pub-6470338276121414~4617708917
///   iOS:     ca-app-pub-6470338276121414~7069741737
///
/// An interstitial is shown right before a test starts (see [showInterstitialThen]).
class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  // ── Ad unit IDs (platform-specific) ────────────────────────────────────────
  static String get _interstitialUnitId => Platform.isIOS
      ? 'ca-app-pub-6470338276121414/9614884728' // iOS interstitial
      : 'ca-app-pub-6470338276121414/8542605504'; // Android interstitial

  /// Rewarded unit IDs — reserved for future use (not wired yet).
  static String get rewardedUnitId => Platform.isIOS
      ? 'ca-app-pub-6470338276121414/1047258868' // iOS rewarded
      : 'ca-app-pub-6470338276121414/6605578004'; // Android rewarded

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _initDone = false;

  // ── Init ────────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initDone) return;
    _initDone = true;
    try {
      // iOS: App Tracking Transparency prompt before using the advertising id.
      if (Platform.isIOS) {
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await Future.delayed(const Duration(milliseconds: 300));
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      }
      await MobileAds.instance.initialize();
      _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      debugPrint('AdService init error: $e');
    }
  }

  // ── Interstitial ─────────────────────────────────────────────────────────────
  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (err) {
          debugPrint('Interstitial failed to load: $err');
          _interstitial = null;
        },
      ),
    );
  }

  /// Shows the interstitial (if ready), then always runs [onDone].
  /// If no ad is ready, [onDone] runs immediately and a new ad is preloaded.
  Future<void> showInterstitialThen(VoidCallback onDone) async {
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      onDone();
      return;
    }
    _interstitial = null;

    bool proceeded = false;
    void go() {
      if (proceeded) return;
      proceeded = true;
      onDone();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
        go();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _loadInterstitial();
        go();
      },
    );

    try {
      ad.show();
    } catch (_) {
      go();
    }
  }

  // ── Rewarded ─────────────────────────────────────────────────────────────────
  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (err) {
          debugPrint('Rewarded failed to load: $err');
          _rewarded = null;
        },
      ),
    );
  }

  /// Shows the rewarded ad (if ready) at a mode entrance, then always runs
  /// [onDone] (to enter the mode). If no ad is ready, [onDone] runs immediately.
  /// Users are never blocked from entering if the ad fails or is closed early.
  Future<void> showRewardedThen(VoidCallback onDone) async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      onDone();
      return;
    }
    _rewarded = null;

    bool proceeded = false;
    void go() {
      if (proceeded) return;
      proceeded = true;
      onDone();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        go();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _loadRewarded();
        go();
      },
    );

    try {
      ad.show(onUserEarnedReward: (ad, reward) {});
    } catch (_) {
      go();
    }
  }

  /// Kept for backward compatibility with existing call sites.
  /// Interstitials now appear only at the start of a test, so these are no-ops
  /// (prevents showing many ads during the 29-test chain / arcade games).
  Future<void> incrementGameCountAndMaybeShow() async {}
  Future<void> showInterstitialIfNeeded() async {}
}
