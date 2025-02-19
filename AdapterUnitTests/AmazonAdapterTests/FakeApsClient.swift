import UIKit

@testable import AmazonAdapter

class FakeApsClient: NSObject, APSClient {

  var delegate: APSClientDelegate?

  private var bannerDelegate: APSClientBannerDelegate? {
    return delegate as? APSClientBannerDelegate
  }

  private var fullScreenAdDelegate: APSClientFullScreenAdDelegate? {
    return delegate as? APSClientFullScreenAdDelegate
  }

  var bannerAdView: UIView {
    return DispatchQueue.main.sync { UIView() }
  }

  static var fetchShouldSucceed = true
  static var initializeShouldSucceed = true
  static var signalsCollectionShouldSucceed = true
  static var sdkVersion = "aps-ios-4.9.7"
  static var triggerImpressionAfterAdLoad = false
  static var triggerAdClickAfterAdLoad = false
  static var showShouldSucceed = true

  static func resetTestFlags() {
    fetchShouldSucceed = true
    initializeShouldSucceed = true
    signalsCollectionShouldSucceed = true
    sdkVersion = "aps-ios-4.9.7"
    triggerImpressionAfterAdLoad = false
    triggerAdClickAfterAdLoad = false
    showShouldSucceed = true
  }

  func initialize(with appId: String, completion: @escaping (NSError?) -> Void) {
    if Self.initializeShouldSucceed {
      completion(nil)
    } else {
      completion(
        NSError(
          domain: "com.fake.aps", code: 12345,
          userInfo: [NSLocalizedDescriptionKey: "Simulated error."]))
    }
  }

  func version() -> String {
    return Self.sdkVersion
  }

  func loadAndCacheApsAd(
    with slotId: String, clientAdFormat: APSClientAdFormat, adSize: CGSize,
    completion: @escaping (AmazonBidLoadingAdapterRequestData?, NSError?) -> Void
  ) {
    if Self.signalsCollectionShouldSucceed {
      completion(
        AmazonBidLoadingAdapterRequestData(
          winningBidPriceEncoded: "winningBidPriceEncoded", adId: "adId",
          width: String(Int(adSize.width)), height: String(Int(adSize.height))), nil)
    } else {
      completion(
        nil,
        NSError(
          domain: "com.fake.aps", code: 12345,
          userInfo: [NSLocalizedDescriptionKey: "Simulated error."]))
    }
  }

  func fetchAd(for adId: String) {
    if Self.fetchShouldSucceed {
      delegate?.fetchedAd()
    } else {
      delegate?.failedToFetchAd(withError: NSError(domain: "com.fake.aps", code: 12345))
    }

    if Self.triggerImpressionAfterAdLoad {
      delegate?.adImpressionFired()
    }

    if Self.triggerAdClickAfterAdLoad {
      delegate?.adClicked()
    }
  }

  func fetchAd(for adId: String, width: CGFloat, height: CGFloat) {
    if Self.fetchShouldSucceed {
      delegate?.fetchedAd()
    } else {
      delegate?.failedToFetchAd(withError: NSError(domain: "com.fake.aps", code: 12345))
    }

    if Self.triggerImpressionAfterAdLoad {
      delegate?.adImpressionFired()
    }

    if Self.triggerAdClickAfterAdLoad {
      delegate?.adClicked()
    }
  }

  func presentFullScreenAd(from viewController: UIViewController) {
    if Self.showShouldSucceed {
      fullScreenAdDelegate?.willPresentAd()
      fullScreenAdDelegate?.didDismissAd()
      fullScreenAdDelegate?.didCompleteAdVideoPlayback()
    } else {
      fullScreenAdDelegate?.failedToPresent(
        withError: NSError(
          domain: "com.fake.aps", code: 12345,
          userInfo: [NSLocalizedDescriptionKey: "Simulated error."]))
    }
  }

}
