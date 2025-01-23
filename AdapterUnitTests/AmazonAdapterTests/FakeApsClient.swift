import Foundation

@testable import AmazonAdapter

class FakeApsClient: APSClient {

  var initializeShouldSucceed = true
  var signalsCollectionShouldSucceed = true
  var sdkVersion = "aps-ios-4.9.7"

  func initialize(with appId: String, completion: @escaping (NSError?) -> Void) {
    if initializeShouldSucceed {
      completion(nil)
    } else {
      completion(
        NSError(
          domain: "com.fake.aps", code: 12345,
          userInfo: [NSLocalizedDescriptionKey: "Simulated error."]))
    }
  }

  func version() -> String {
    return sdkVersion
  }

  func loadAndCacheApsAd(
    with slotId: String, adSize: CGSize,
    completion: @escaping (AmazonBidLoadingAdapterRequestData?, NSError?) -> Void
  ) {
    if signalsCollectionShouldSucceed {
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

}
