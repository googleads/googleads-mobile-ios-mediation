import Foundation
import GoogleMobileAds
import MolocoSDK

/// Loads and presents interstitial ads on Moloco ads SDK.
final class InterstitialAdLoader: NSObject {

  /// The interstitial ad configuration.
  private let adConfiguration: GADMediationInterstitialAdConfiguration

  /// The completion handler to call when interstitial ad loading succeeds or fails.
  private let loadCompletionHandler: GADMediationInterstitialLoadCompletionHandler

  /// The ad event delegate which is used to report interstitial related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: GADMediationInterstitialAdEventDelegate?

  private var molocoInterstitialFactory: MolocoInterstitialFactory

  private var interstitialAd: MolocoInterstitial?

  init(
    adConfiguration: GADMediationInterstitialAdConfiguration,
    loadCompletionHandler: @escaping GADMediationInterstitialLoadCompletionHandler,
    molocoInterstitialFactory: MolocoInterstitialFactory
  ) {
    self.adConfiguration = adConfiguration
    self.loadCompletionHandler = loadCompletionHandler
    self.molocoInterstitialFactory = molocoInterstitialFactory
    super.init()
  }

  func loadAd() {
    guard #available(iOS 13.0, *) else {
      let error = MolocoUtils.error(
        code: MolocoAdapterErrorCode.adServingNotSupported,
        description: "Moloco SDK does not support serving ads on iOS 12 and below")
      _ = loadCompletionHandler(nil, error)
      return
    }

    let molocoAdUnitId = MolocoUtils.getAdUnitId(from: adConfiguration)
    guard let molocoAdUnitId = molocoAdUnitId else {
      let error = MolocoUtils.error(
        code: MolocoAdapterErrorCode.invalidAdUnitId, description: "Missing required parameter")
      _ = loadCompletionHandler(nil, error)
      return
    }

    DispatchQueue.main.async {
      self.interstitialAd = self.molocoInterstitialFactory.createInterstitial(
        for: molocoAdUnitId, delegate: self)
      self.interstitialAd?.load(bidResponse: self.adConfiguration.bidResponse ?? "")
    }
  }

}

// MARK: - GADMediationInterstitialAd

extension InterstitialAdLoader: GADMediationInterstitialAd {

  func present(from viewController: UIViewController) {
    eventDelegate?.willPresentFullScreenView()
    // TODO: implement
  }

}

// MARK: - MolocoInterstitialDelegate

extension InterstitialAdLoader: MolocoInterstitialDelegate {
  func didLoad(ad: any MolocoSDK.MolocoAd) {
    eventDelegate = loadCompletionHandler(self, nil)
  }

  func failToLoad(ad: any MolocoSDK.MolocoAd, with error: (any Error)?) {
    _ = loadCompletionHandler(nil, error)
  }

  func didShow(ad: any MolocoSDK.MolocoAd) {
    // TODO: implement
  }

  func failToShow(ad: any MolocoSDK.MolocoAd, with error: (any Error)?) {
    // TODO: implement
  }

  func didHide(ad: any MolocoSDK.MolocoAd) {
    // TODO: implement
  }

  func didClick(on ad: any MolocoSDK.MolocoAd) {
    // TODO: implement
  }

}
