import XCTest

final class MolocoTestUtils {

  static func flushMainThread(_ testCase: XCTestCase) {
    let expectation = testCase.expectation(description: "Flushed.")
    DispatchQueue.main.async {
      expectation.fulfill()
    }
    testCase.wait(for: [expectation])
  }

}
