import Foundation
import GoogleMobileAds
import HyBid

@testable import VerveAdapter

final class FakeHyBidClient: NSObject, HybidClient {

  var shouldInitializationSucceed = true
  var shouldGetBannerSizeSucceed = true
  var shouldAdLoadSucceed = true

  func version() -> String {
    return "1.2.3"
  }

  func initialize(
    with appToken: String,
    testMode: Bool,
    COPPA: Bool?,
    TFUA: Bool?,
    completionHandler: @escaping (VerveAdapterError?) -> Void
  ) {
    if shouldInitializationSucceed {
      completionHandler(nil)
    } else {
      completionHandler(
        VerveAdapterError(
          errorCode: .failedToInitializeHyBidSDK, description: "Failed to initialize."))
    }
  }

  func collectSignals() -> String {
    return "signals"
  }

  func getBannerSize(_ size: CGSize) throws(VerveAdapterError) -> HyBidAdSize {
    if shouldGetBannerSizeSucceed {
      return .size_320x100
    }
    throw VerveAdapterError(errorCode: .unsupportedBannerSize, description: "")
  }

  func loadRTBBannerAd(
    with bidResponse: String,
    size: CGSize,
    delegate: any HyBidAdViewDelegate
  ) throws(VerveAdapterError) {
    if shouldAdLoadSucceed {
      delegate.adViewDidLoad(HyBidAdView(size: .size_320x50))
    } else {
      delegate.adView(
        HyBidAdView(size: .size_320x50),
        didFailWithError: NSError(domain: "com.test.verveadapter", code: 12345, userInfo: nil))
    }
  }

}
