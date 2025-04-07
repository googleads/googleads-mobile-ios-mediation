import AdapterUnitTestKit
import GoogleMobileAds
import Testing

@testable import AmazonAdapter

@Suite("Amazon adapter banner fetch")
final class AmazonAdapterLoadBannerTests {

  init() {
    setenv("FAKE_APS_CLIENT_CLASS_NAME", "AmazonAdapterTests.FakeApsClient", 1)
  }

  deinit {
    FakeApsClient.resetTestFlags()
  }

  @Test("Successful banner load")
  func loadBanner_succeeds() async {
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id", width: 100, height: 100)]
    ).jsonStringEncode()
    let adapter = AmazonBidLoadingAdapter()
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, error in
        #expect(banner != nil)
        #expect(banner?.view is UIView)
        #expect(error == nil)
        continuation.resume()
        return AUTKMediationBannerAdEventDelegate()
      }
    }
  }

  @Test("Unsuccessful banner load because bid response is missing")
  func loadBanner_fails_whenConfigurationDoesNotContainBidResponse() async {
    let config = AUTKMediationBannerAdConfiguration()
    let adapter = AmazonBidLoadingAdapter()
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, error in
        #expect(banner == nil)
        let error = error as? NSError
        #expect(error != nil)
        #expect(error!.domain == AmazonBidLoadingAdapterError.domain)
        #expect(
          error!.code
            == AmazonBidLoadingAdapterError.Category.bannerAdConfigurationsMissingBidResponse
            .rawValue
        )
        continuation.resume()
        return AUTKMediationBannerAdEventDelegate()
      }
    }
  }

  @Test("Unsuccessful banner load because bid response is invalid json")
  func loadBanner_fails_whenConfigurationContainsInvalidBidResponse() async {
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "Invalid"
    let adapter = AmazonBidLoadingAdapter()
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, error in
        #expect(banner == nil)
        let error = error as? NSError
        #expect(error != nil)
        #expect(error!.domain == AmazonBidLoadingAdapterError.domain)
        #expect(
          error!.code
            == AmazonBidLoadingAdapterError.Category.responseDataJsonStringDecodingFailure.rawValue)
        continuation.resume()
        return AUTKMediationBannerAdEventDelegate()
      }
    }
  }

  @Test("Unsuccessful banner load because bid response does not contain an ad ID")
  func loadBanner_fails_whenConfigurationContainsBidResponseWithoutAdId() async {
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(width: 100, height: 100)]
    ).jsonStringEncode()
    let adapter = AmazonBidLoadingAdapter()
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, error in
        #expect(banner == nil)
        let error = error as? NSError
        #expect(error != nil)
        #expect(error!.domain == AmazonBidLoadingAdapterError.domain)
        #expect(error!.code == AmazonBidLoadingAdapterError.Category.invalidBidResponse.rawValue)
        continuation.resume()
        return AUTKMediationBannerAdEventDelegate()
      }
    }
  }

  @Test("Unsuccessful banner load because APS fails to fetch")
  func loadBanner_fails_whenApsSdkFailsToFetchAd() async {
    FakeApsClient.fetchShouldSucceed = false

    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id", width: 100, height: 100)]
    ).jsonStringEncode()
    let adapter = AmazonBidLoadingAdapter()
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, error in
        #expect(banner == nil)
        let error = error as? NSError
        #expect(error != nil)
        #expect(error!.domain == "com.fake.aps")
        #expect(error!.code == 12345)
        continuation.resume()
        return AUTKMediationBannerAdEventDelegate()
      }
    }
  }

}

@Suite("Amazon adapter banner events")
struct AmazonAdapterBannerEventTests {

  init() {
    FakeApsClient.resetTestFlags()
    setenv("FAKE_APS_CLIENT_CLASS_NAME", "AmazonAdapterTests.FakeApsClient", 1)
  }

  @Test("Report ad impression")
  func adImpression() async throws {
    FakeApsClient.triggerImpressionAfterAdLoad = true

    let eventDelegate = AUTKMediationBannerAdEventDelegate()
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id", width: 100, height: 100)]
    ).jsonStringEncode()
    let adapter = AmazonBidLoadingAdapter()

    adapter.loadBanner(for: config) { banner, error in
      #expect(banner != nil)
      #expect(error == nil)
      #expect(eventDelegate.reportImpressionInvokeCount == 0)
      return eventDelegate
    }

    await withCheckedContinuation { continuation in
      while eventDelegate.reportImpressionInvokeCount == 0 {}
      #expect(eventDelegate.reportImpressionInvokeCount == 1)
      continuation.resume()
    }
  }

  @Test("Report ad click")
  func adClick() async throws {
    FakeApsClient.triggerAdClickAfterAdLoad = true

    let eventDelegate = AUTKMediationBannerAdEventDelegate()
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id", width: 100, height: 100)]
    ).jsonStringEncode()
    let adapter = AmazonBidLoadingAdapter()

    adapter.loadBanner(for: config) { banner, error in
      #expect(banner != nil)
      #expect(error == nil)
      #expect(eventDelegate.reportClickInvokeCount == 0)
      return eventDelegate
    }

    await withCheckedContinuation { continuation in
      while eventDelegate.reportClickInvokeCount == 0 {}
      #expect(eventDelegate.reportClickInvokeCount == 1)
      continuation.resume()
    }
  }

}

extension AmazonBidLoadingAdapterResponseData {

  func jsonStringEncode() throws -> String? {
    do {
      let jsonData = try JSONEncoder().encode(self)
      return String(data: jsonData, encoding: .utf8)
    } catch {
      throw AmazonBidLoadingAdapterError(
        category: .requestDataEncodingFailure,
        description: "Failed to JSON encode a request data: \(description())")
    }
  }

}
