import Foundation
import GoogleMobileAds

/// Loads and presents interstitial ads on Moloco ads SDK.
final class InterstitialAdLoader {

  /// The interstitial ad configuration.
  private let adConfiguration: GADMediationInterstitialAdConfiguration

  /// The ad event delegate which is used to report interstitial related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: GADMediationInterstitialAdEventDelegate?

  init(
    adConfiguration: GADMediationInterstitialAdConfiguration,
    loadCompletionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    super.init()
  }

  func loadAd() {
    // TODO: implement and make sure to call |interstitialAdLoadCompletionHandler| after loading an ad.
  }

}

// MARK: - GADMediationInterstitialAd

extension InterstitialAdLoader: GADMediationInterstitialAd {

  func present(from viewController: UIViewController) {
    eventDelegate?.willPresentFullScreenView()
    // TODO: implement
  }

}

// MARK: - <OtherProtocol>
// TODO: extend and implement any other protocol, if any.
