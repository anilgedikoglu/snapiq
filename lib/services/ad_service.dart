import 'dart:developer' as developer;

/// AdService — reklam altyapısı.
/// Debug modda gerçek reklam gösterilmez, sadece log yazılır.
/// Gerçek AdMob entegrasyonu için TODO alanlarını doldurun.
class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  int _completedGames = 0;

  // TODO: Gerçek AdMob uygulama ID'sini AndroidManifest.xml'e ekleyin
  // TODO: Aşağıdaki test ID'lerini gerçek ID'lerle değiştirin
  static const String _interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712'; // Test ID

  Future<void> initialize() async {
    developer.log('AdService: initialize() çağrıldı (debug modu — gerçek reklam yok)');
    // TODO: await MobileAds.instance.initialize();
    // TODO: loadInterstitial();
  }

  Future<void> loadInterstitial() async {
    developer.log('AdService: loadInterstitial() — Unit ID: $_interstitialAdUnitId');
    // TODO: InterstitialAd.load(
    //   adUnitId: _interstitialAdUnitId,
    //   request: const AdRequest(),
    //   adLoadCallback: InterstitialAdLoadCallback(...),
    // );
  }

  Future<void> showInterstitialIfNeeded() async {
    developer.log('AdService: Interstitial would be shown here');
    // TODO: _interstitialAd?.show();
    await loadInterstitial();
  }

  Future<void> incrementGameCountAndMaybeShow() async {
    _completedGames++;
    developer.log('AdService: completedGames=$_completedGames');
    if (_completedGames % 2 == 0) {
      await showInterstitialIfNeeded();
    }
  }
}
