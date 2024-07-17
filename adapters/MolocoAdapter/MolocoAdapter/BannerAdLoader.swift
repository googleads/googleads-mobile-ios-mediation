import Foundation
import GoogleMobileAds

/// Loads banner ads on Moloco ads SDK.
final class BannerAdLoader: NSObject {

  /// The banner ad configuration.
  private let adConfiguration: GADMediationBannerAdConfiguration

  /// The ad event delegate which is used to report banner related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: GADMediationBannerAdEventDelegate?

  init(
    adConfiguration: GADMediationBannerAdConfiguration,
    loadCompletionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    super.init()
  }

  func loadAd() {
    // TODO: implement and make sure to call |bannerAdLoadCompletionHandler| after loading an ad.
  }

}

// MARK: - GADMediationBannerAd

extension BannerAdLoader: GADMediationBannerAd {
  var view: UIView {
    // TODO: implement
    return UIView()
  }
}

// MARK: - <OtherProtocol>
// TODO: extend and implement any other protocol, if any.
