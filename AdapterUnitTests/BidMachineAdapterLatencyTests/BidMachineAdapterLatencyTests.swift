import AdapterUnitTestKit
import XCTest

@testable import GoogleBidMachineAdapter

class BidMachineAdapterLatencyTests: XCTestCase {

  func testAdapterVersionLatency() {
    AUTKTestAdapterVersionLatency(BidMachineAdapter.self)
  }

  func testAdSDKVersionLatency() {
    AUTKTestAdSDKVersionLatency(BidMachineAdapter.self)
    AUTKTestAdSDKVersionLatency(BidMachineAdapter.self)
  }

}
