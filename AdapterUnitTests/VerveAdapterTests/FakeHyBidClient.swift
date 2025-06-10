import Foundation
import GoogleMobileAds
import HyBid

@testable import VerveAdapter

final class FakeHyBidClient: NSObject, HybidClient {

  func version() -> String {
    return "1.2.3"
  }

}
