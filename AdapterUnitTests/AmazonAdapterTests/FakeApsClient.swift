import Foundation

@testable import AmazonAdapter

class FakeApsClient: APSClient {

  var initializeShouldSucceed = true
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

}
