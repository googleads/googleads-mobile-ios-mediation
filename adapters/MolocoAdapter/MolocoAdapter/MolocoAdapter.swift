import GoogleMobileAds

/// Adapter for Google Mobile Ads SDK to render ads on Moloco ads SDK.
// TODO: if the adapter supports bidding, it must conforms to GADRTBAdapter instead of GADMediationAdapter.
@objc(GADMediationAdapterMoloco)
final class MolocoAdapter: NSObject, GADMediationAdapter /*GADRTBAdapter */ {

  /// The banner ad loader.
  private var bannerAdLoader: BannerAdLoader?

  /// The interstitial ad loader.
  private var interstitialAdLoader: InterstitialAdLoader?

  /// The rewarded ad loader.
  private var rewardedAdLoader: RewardedAdLoader?

  /// The native ad loader.
  private var nativeAdLoader: NativeAdLoader?

  @objc static func setUpWith(
    _ configuration: GADMediationServerConfiguration,
    completionHandler: @escaping GADMediationAdapterSetUpCompletionBlock
  ) {
    // TODO: implement
    completionHandler(nil)
  }

  @objc static func networkExtrasClass() -> (any GADAdNetworkExtras.Type)? {
    return nil
  }

  @objc static func adapterVersion() -> GADVersionNumber {
    // TODO: implement
    return GADVersionNumber(majorVersion: 0, minorVersion: 0, patchVersion: 0)
  }

  @objc static func adSDKVersion() -> GADVersionNumber {
    // TODO: implement
    return GADVersionNumber(majorVersion: 0, minorVersion: 0, patchVersion: 0)
  }

  // TODO: Implement if the adapter conforms to GADRTBAdapter. Otherwise, remove.
  //@objc func collectSignals(for params: GADRTBRequestParameters, completionHandler: @escaping GADRTBSignalCompletionHandler) {
  //
  //}

  // TODO: Remove if not needed. If removed, then remove the |BannerAdLoader| class as well.
  @objc func loadBanner(
    for adConfiguration: GADMediationBannerAdConfiguration,
    completionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    bannerAdLoader = BannerAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    bannerAdLoader?.loadAd()
  }

  // TODO: Remove if not needed. If removed, then remove the |InterstitialAdLoader| class as well.
  @objc func loadInterstitial(
    for adConfiguration: GADMediationInterstitialAdConfiguration,
    completionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    interstitialAdLoader = InterstitialAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    interstitialAdLoader?.loadAd()
  }

  // TODO: Remove if not needed. If removed, then remove the |RewardedAdLoader| class as well.
  @objc func loadRewardedAd(
    for adConfiguration: GADMediationRewardedAdConfiguration,
    completionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    rewardedAdLoader = RewardedAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    rewardedAdLoader?.loadAd()
  }

  // TODO: Remove if not needed. If removed, then remove the |NativeAdLoader| class as well.
  @objc func loadNativeAd(
    for adConfiguration: GADMediationNativeAdConfiguration,
    completionHandler: @escaping GADMediationNativeLoadCompletionHandler
  ) {
    nativeAdLoader = NativeAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    nativeAdLoader?.loadAd()
  }

}
