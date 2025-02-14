import UIKit

@testable import AmazonAdapter

class FakeApsClient: NSObject, APSClient {

  var bannerAdView: UIView {
    return DispatchQueue.main.sync { UIView() }
  }
  var bannerDelegate: APSClientBannerDelegate?

  static var fetchShouldSucceed = true
  static var initializeShouldSucceed = true
  static var signalsCollectionShouldSucceed = true
  static var sdkVersion = "aps-ios-4.9.7"
  static var triggerImpressionAfterAdLoad = false
  static var triggerAdClickAfterAdLoad = false

  static func resetTestFlags() {
    fetchShouldSucceed = true
    initializeShouldSucceed = true
    signalsCollectionShouldSucceed = true
    sdkVersion = "aps-ios-4.9.7"
    triggerImpressionAfterAdLoad = false
    triggerAdClickAfterAdLoad = false
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

  func fetchBannerAd(for adId: String, width: CGFloat, height: CGFloat) {
    if Self.fetchShouldSucceed {
      bannerDelegate?.fetchedAd()
    } else {
      bannerDelegate?.failedToFetchAd(withError: NSError(domain: "com.fake.aps", code: 12345))
    }

    if Self.triggerImpressionAfterAdLoad {
      bannerDelegate?.adImpressionFired()
    }

    if Self.triggerAdClickAfterAdLoad {
      bannerDelegate?.adClicked()
    }
  }

}
