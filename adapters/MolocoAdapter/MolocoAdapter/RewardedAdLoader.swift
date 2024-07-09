import Foundation
import GoogleMobileAds

/// Loads and presents rewarded ads on Moloco ads SDK.
final class RewardedAdLoader {

  /// The rewarded ad configuration.
  private let adConfiguration: GADMediationRewardedAdConfiguration

  /// The ad event delegate which is used to report rewarded related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: GADMediationRewardedAdEventDelegate?

  init(
    adConfiguration: GADMediationRewardedAdConfiguration,
    loadCompletionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    super.init()
  }

  func loadAd() {
    // TODO: implement and make sure to call |rewardedAdLoadCompletionHandler| after loading an ad.
  }

}

// MARK: - GADMediationRewardedAd

extension RewardedAdLoader: GADMediationRewardedAd {

  func present(from viewController: UIViewController) {
    eventDelegate?.willPresentFullScreenView()
    // TODO: implement
  }

}

// MARK: - <OtherProtocol>
// TODO: extend and implement any other protocol, if any.
