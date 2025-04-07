import AdapterUnitTestKit
import GoogleMobileAds
import Testing

@testable import AmazonAdapter

@Suite("Amazon adapter interstitial fetch")
final class AmazonAdapterLoadInterstitialTests {

  init() {
    setenv("FAKE_APS_CLIENT_CLASS_NAME", "AmazonAdapterTests.FakeApsClient", 1)
  }

  deinit {
    FakeApsClient.resetTestFlags()
  }

  @Test("Successful interstitial load")
  func loadInterstitial_succeeds() {
    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id")]
    ).jsonStringEncode()
    let adapter = AmazonBidLoadingAdapter()
    adapter.loadInterstitial(for: config) { interstitial, error in
      #expect(interstitial != nil)
      #expect(error == nil)
      return AUTKMediationInterstitialAdEventDelegate()
    }
  }

  @Test("Unsuccessful interstitial load because bid response is missing")
  func loadInterstitial_fails_whenConfigurationDoesNotContainBidResponse() {
    let config = AUTKMediationInterstitialAdConfiguration()
    let adapter = AmazonBidLoadingAdapter()
    adapter.loadInterstitial(for: config) { interstitial, error in
      #expect(interstitial == nil)
      let error = error as? NSError
      #expect(error != nil)
      #expect(error!.domain == AmazonBidLoadingAdapterError.domain)
      #expect(
        error!.code
          == AmazonBidLoadingAdapterError.Category.interstitialAdConfigurationsMissingBidResponse
          .rawValue
      )
      return AUTKMediationInterstitialAdEventDelegate()
    }
  }

  @Test("Unsuccessful interstitial load because bid response is invalid json")
  func loadInterstitial_fails_whenConfigurationContainsInvalidBidResponse() {
    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "Invalid"
    let adapter = AmazonBidLoadingAdapter()
    adapter.loadInterstitial(for: config) { interstitial, error in
      #expect(interstitial == nil)
      let error = error as? NSError
      #expect(error != nil)
      #expect(error!.domain == AmazonBidLoadingAdapterError.domain)
      #expect(
        error!.code
          == AmazonBidLoadingAdapterError.Category.responseDataJsonStringDecodingFailure.rawValue)
      return AUTKMediationInterstitialAdEventDelegate()
    }
  }

  @Test("Unsuccessful interstitial load because bid response does not contain an ad ID")
  func loadInterstitial_fails_whenConfigurationContainsBidResponseWithoutAdId() {
    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(width: 100, height: 100)]
    ).jsonStringEncode()
    let adapter = AmazonBidLoadingAdapter()
    adapter.loadInterstitial(for: config) { interstitial, error in
      #expect(interstitial == nil)
      let error = error as? NSError
      #expect(error != nil)
      #expect(error!.domain == AmazonBidLoadingAdapterError.domain)
      #expect(error!.code == AmazonBidLoadingAdapterError.Category.invalidBidResponse.rawValue)
      return AUTKMediationInterstitialAdEventDelegate()
    }
  }

  @Test("Unsuccessful interstitial load because APS fails to fetch")
  func loadInterstitial_fails_whenApsSdkFailsToFetchAd() {
    FakeApsClient.fetchShouldSucceed = false

    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id")]
    ).jsonStringEncode()
    let adapter = AmazonBidLoadingAdapter()
    adapter.loadInterstitial(for: config) { interstitial, error in
      #expect(interstitial == nil)
      let error = error as? NSError
      #expect(error != nil)
      #expect(error!.domain == "com.fake.aps")
      #expect(error!.code == 12345)
      return AUTKMediationInterstitialAdEventDelegate()
    }
  }

}

@Suite("Amazon adapter interstitial events")
struct AmazonAdapterInterstitialEventTests {

  init() {
    FakeApsClient.resetTestFlags()
    setenv("FAKE_APS_CLIENT_CLASS_NAME", "AmazonAdapterTests.FakeApsClient", 1)
  }

  @Test("Report ad impression")
  func adImpression() {
    FakeApsClient.triggerImpressionAfterAdLoad = true

    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id")]
    ).jsonStringEncode()
    let adapter = AmazonBidLoadingAdapter()
    adapter.loadInterstitial(for: config) { interstitial, error in
      #expect(interstitial != nil)
      #expect(error == nil)
      #expect(eventDelegate.reportImpressionInvokeCount == 0)
      return eventDelegate
    }
    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

  @Test("Report ad click")
  func adClick() {
    FakeApsClient.triggerAdClickAfterAdLoad = true

    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id")]
    ).jsonStringEncode()
    let adapter = AmazonBidLoadingAdapter()
    adapter.loadInterstitial(for: config) { interstitial, error in
      #expect(interstitial != nil)
      #expect(error == nil)
      #expect(eventDelegate.reportClickInvokeCount == 0)
      return eventDelegate
    }
    #expect(eventDelegate.reportClickInvokeCount == 1)
  }

  @Test("Succeed to present an interstitial ad")
  func pressentInterstitial_succeeds() async {
    FakeApsClient.showShouldSucceed = true

    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id")]
    ).jsonStringEncode()

    let adapter = AmazonBidLoadingAdapter()
    await confirmation("Ad load") { loaded in
      adapter.loadInterstitial(for: config) { interstitial, error in
        defer {
          loaded()
        }
        #expect(interstitial != nil)
        #expect(error == nil)
        eventDelegate.interstitialAd = interstitial
        return eventDelegate
      }
    }

    await eventDelegate.interstitialAd?.present(from: UIViewController())
    #expect(eventDelegate.willPresentFullScreenViewInvokeCount == 1)
    #expect(eventDelegate.didDismissFullScreenViewInvokeCount == 1)
  }

  @Test("Fail to present an interstitial ad")
  func pressentInterstitial_fails() async {
    FakeApsClient.showShouldSucceed = false

    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id")]
    ).jsonStringEncode()

    let adapter = AmazonBidLoadingAdapter()
    await confirmation("Ad load") { loaded in
      adapter.loadInterstitial(for: config) { interstitial, error in
        defer {
          loaded()
        }
        #expect(interstitial != nil)
        #expect(error == nil)
        eventDelegate.interstitialAd = interstitial
        return eventDelegate
      }
    }

    await eventDelegate.interstitialAd?.present(from: UIViewController())
    #expect(eventDelegate.didFailToPresentError != nil)
  }

}
