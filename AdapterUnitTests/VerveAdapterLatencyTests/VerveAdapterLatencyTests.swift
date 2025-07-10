import AdapterUnitTestKit
import XCTest

@testable import VerveAdapter

class VerveAdapterLatencyTests: XCTestCase {

  func testAdapterVersionLatency() {
    AUTKTestAdapterVersionLatency(VerveAdapter.self)
  }

  func testAdSDKVersionLatency() {
    AUTKTestAdSDKVersionLatency(VerveAdapter.self)
    AUTKTestAdSDKVersionLatency(VerveAdapter.self)
  }

}
