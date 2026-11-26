class SplashConfigModel {
  final int durationSeconds;
  final String logoAssetPath;
  final String brandTitle;

  const SplashConfigModel({
    this.durationSeconds = 2,
    this.logoAssetPath = 'assets/images/logo.png',
    this.brandTitle = 'Janta Bakery',
  });
}