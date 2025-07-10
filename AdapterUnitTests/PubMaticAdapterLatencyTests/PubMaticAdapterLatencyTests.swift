import AdapterUnitTestKit
import XCTest

@testable import PubMaticAdapter

class PubMaticAdapterLatencyTests: XCTestCase {

  func testAdapterVersionLatency() {
    AUTKTestAdapterVersionLatency(PubMaticAdapter.self)
  }

  func testAdSDKVersionLatency() {
    AUTKTestAdSDKVersionLatency(PubMaticAdapter.self)
    AUTKTestAdSDKVersionLatency(PubMaticAdapter.self)
  }

}
