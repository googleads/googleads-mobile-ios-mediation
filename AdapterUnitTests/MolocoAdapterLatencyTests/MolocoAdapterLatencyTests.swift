import AdapterUnitTestKit
import XCTest

@testable import MolocoAdapter

class MolocoAdapterLatencyTests: XCTestCase {

  func testAdapterVersionLatency() {
    AUTKTestAdapterVersionLatency(MolocoMediationAdapter.self)
  }

  func testAdSDKVersionLatency() {
    AUTKTestAdSDKVersionLatency(MolocoMediationAdapter.self)
    AUTKTestAdSDKVersionLatency(MolocoMediationAdapter.self)
  }

}
