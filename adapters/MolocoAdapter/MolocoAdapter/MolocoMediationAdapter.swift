import GoogleMobileAds
import MolocoSDK
import OSLog

/// Adapter for Google Mobile Ads SDK to render ads on Moloco ads SDK.
// TODO: if the adapter supports bidding, it must conforms to GADRTBAdapter instead of GADMediationAdapter.
@objc(GADMediationAdapterMoloco)
public final class MolocoMediationAdapter: NSObject, GADMediationAdapter /*GADRTBAdapter */ {

  /// The banner ad loader.
  private var bannerAdLoader: BannerAdLoader?

  /// The interstitial ad loader.
  private var interstitialAdLoader: InterstitialAdLoader?

  /// The rewarded ad loader.
  private var rewardedAdLoader: RewardedAdLoader?

  /// The native ad loader.
  private var nativeAdLoader: NativeAdLoader?

  private static var molocoInitializer: MolocoInitializer = MolocoSdkImpl()

  private var molocoInterstitialFactory: MolocoInterstitialFactory

  public override init() {
    molocoInterstitialFactory = MolocoSdkImpl()
  }

  /// Initializer used only for testing purpose.
  public init(molocoInterstitialFactory: MolocoInterstitialFactory) {
    self.molocoInterstitialFactory = molocoInterstitialFactory
  }

  /// Setter used only for testing purpose.
  public static func setMolocoInitializer(_ fakeMolocoInitializer: MolocoInitializer) {
    molocoInitializer = fakeMolocoInitializer
  }

  @objc public static func setUpWith(
    _ configuration: GADMediationServerConfiguration,
    completionHandler: @escaping GADMediationAdapterSetUpCompletionBlock
  ) {
    guard #available(iOS 13.0, *) else {
      completionHandler(
        MolocoUtils.error(
          code: MolocoAdapterErrorCode.adServingNotSupported,
          description: "Moloco SDK does not support serving ads on iOS 12 and below"))
      return
    }

    var appIds = [String]()
    for credential in configuration.credentials {
      if let appIdString = credential.settings[MolocoConstants.appIdKey] as? String,
        !appIdString.isEmpty
      {
        appIds.append(appIdString)
      }
    }

    guard !appIds.isEmpty else {
      MolocoUtils.log("Not initializing Moloco SDK because because appId is invalid/missing")
      completionHandler(
        MolocoUtils.error(
          code: MolocoAdapterErrorCode.invalidAppId, description: "Missing/Invalid App ID"))
      return
    }

    if appIds.count > 1 {
      MolocoUtils.log(
        "Found multiple application IDs. Please remove unused application IDs from the AdMob UI. Application IDs: \(appIds)"
      )
    }

    let appId = appIds.first

    guard let appId = appId else {
      completionHandler(
        MolocoUtils.error(
          code: MolocoAdapterErrorCode.invalidAppId, description: "Missing/Invalid App ID"))
      return
    }

    MolocoUtils.log("Initializing Moloco SDK with app ID [\(appId)]")

    // Check if already initialized
    if molocoInitializer.isInitialized() {
      completionHandler(nil)
      return
    }

    // Initialize Moloco SDK
    molocoInitializer.initialize(initParams: .init(appKey: appId)) { done, err in
      if done {
        completionHandler(nil)
      } else {
        completionHandler(err)
      }
    }
  }

  @objc public static func networkExtrasClass() -> (any GADAdNetworkExtras.Type)? {
    return nil
  }

  @objc public static func adapterVersion() -> GADVersionNumber {
    // TODO: implement
    return GADVersionNumber(majorVersion: 0, minorVersion: 0, patchVersion: 0)
  }

  @objc public static func adSDKVersion() -> GADVersionNumber {
    // TODO: implement
    return GADVersionNumber(majorVersion: 0, minorVersion: 0, patchVersion: 0)
  }

  // TODO: Implement if the adapter conforms to GADRTBAdapter. Otherwise, remove.
  //@objc func collectSignals(for params: GADRTBRequestParameters, completionHandler: @escaping GADRTBSignalCompletionHandler) {
  //
  //}

  // TODO: Remove if not needed. If removed, then remove the |BannerAdLoader| class as well.
  @objc public func loadBanner(
    for adConfiguration: GADMediationBannerAdConfiguration,
    completionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    bannerAdLoader = BannerAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    bannerAdLoader?.loadAd()
  }

  @objc public func loadInterstitial(
    for adConfiguration: GADMediationInterstitialAdConfiguration,
    completionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    interstitialAdLoader = InterstitialAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler,
      molocoInterstitialFactory: molocoInterstitialFactory)
    interstitialAdLoader?.loadAd()
  }

  // TODO: Remove if not needed. If removed, then remove the |RewardedAdLoader| class as well.
  @objc public func loadRewardedAd(
    for adConfiguration: GADMediationRewardedAdConfiguration,
    completionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    rewardedAdLoader = RewardedAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    rewardedAdLoader?.loadAd()
  }

  // TODO: Remove if not needed. If removed, then remove the |NativeAdLoader| class as well.
  @objc public func loadNativeAd(
    for adConfiguration: GADMediationNativeAdConfiguration,
    completionHandler: @escaping GADMediationNativeLoadCompletionHandler
  ) {
    nativeAdLoader = NativeAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    nativeAdLoader?.loadAd()
  }

}
