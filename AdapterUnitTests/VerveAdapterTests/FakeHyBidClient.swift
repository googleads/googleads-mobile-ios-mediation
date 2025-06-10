import Foundation
import GoogleMobileAds
import HyBid

@testable import VerveAdapter

final class FakeHyBidClient: NSObject, HybidClient {

  var shouldInitializationSucceed = true

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

}
