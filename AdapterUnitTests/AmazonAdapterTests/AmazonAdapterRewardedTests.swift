import AdapterUnitTestKit
import GoogleMobileAds
import Testing

@testable import AmazonAdapter

@Suite("Amazon adapter rewarded fetch")
final class AmazonAdapterLoadRewardedTests {

  init() {
    setenv("FAKE_APS_CLIENT_CLASS_NAME", "AmazonAdapterTests.FakeApsClient", 1)
  }

  deinit {
    FakeApsClient.resetTestFlags()
  }

  @Test("Successful rewarded load")
  func loadRewardedAd_succeeds() {
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id")]
    ).jsonStringEncode()
    let adapter = AmazonBidLoadingAdapter()
    adapter.loadRewardedAd(for: config) { rewarded, error in
      #expect(rewarded != nil)
      #expect(error == nil)
      return AUTKMediationRewardedAdEventDelegate()
    }
  }

  @Test("Unsuccessful rewarded load because bid response is missing")
  func loadRewardedAd_fails_whenConfigurationDoesNotContainBidResponse() {
    let config = AUTKMediationRewardedAdConfiguration()
    let adapter = AmazonBidLoadingAdapter()
    adapter.loadRewardedAd(for: config) { rewarded, error in
      #expect(rewarded == nil)
      let error = error as? NSError
      #expect(error != nil)
      #expect(error!.domain == AmazonBidLoadingAdapterError.domain)
      #expect(
        error!.code
          == AmazonBidLoadingAdapterError.Category.rewardedAdConfigurationsMissingBidResponse
          .rawValue
      )
      return AUTKMediationRewardedAdEventDelegate()
    }
  }

  @Test("Unsuccessful rewarded load because bid response is invalid json")
  func loadRewardedAd_fails_whenConfigurationContainsInvalidBidResponse() {
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "Invalid"
    let adapter = AmazonBidLoadingAdapter()
    adapter.loadRewardedAd(for: config) { rewarded, error in
      #expect(rewarded == nil)
      let error = error as? NSError
      #expect(error != nil)
      #expect(error!.domain == AmazonBidLoadingAdapterError.domain)
      #expect(
        error!.code
          == AmazonBidLoadingAdapterError.Category.responseDataJsonStringDecodingFailure.rawValue)
      return AUTKMediationRewardedAdEventDelegate()
    }
  }

  @Test("Unsuccessful rewarded load because bid response does not contain an ad ID")
  func loadRewardedAd_fails_whenConfigurationContainsBidResponseWithoutAdId() {
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData()]
    ).jsonStringEncode()
    let adapter = AmazonBidLoadingAdapter()
    adapter.loadRewardedAd(for: config) { rewarded, error in
      #expect(rewarded == nil)
      let error = error as? NSError
      #expect(error != nil)
      #expect(error!.domain == AmazonBidLoadingAdapterError.domain)
      #expect(error!.code == AmazonBidLoadingAdapterError.Category.invalidBidResponse.rawValue)
      return AUTKMediationRewardedAdEventDelegate()
    }
  }

  @Test("Unsuccessful rewarded load because APS fails to fetch")
  func loadRewardedAd_fails_whenApsSdkFailsToFetchAd() {
    FakeApsClient.fetchShouldSucceed = false

    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id")]
    ).jsonStringEncode()
    let adapter = AmazonBidLoadingAdapter()
    adapter.loadRewardedAd(for: config) { rewarded, error in
      #expect(rewarded == nil)
      let error = error as? NSError
      #expect(error != nil)
      #expect(error!.domain == "com.fake.aps")
      #expect(error!.code == 12345)
      return AUTKMediationRewardedAdEventDelegate()
    }
  }

}

@Suite("Amazon adapter rewarded events")
struct AmazonAdapterRewardedEventTests {

  init() {
    FakeApsClient.resetTestFlags()
    setenv("FAKE_APS_CLIENT_CLASS_NAME", "AmazonAdapterTests.FakeApsClient", 1)
  }

  @Test("Report ad impression")
  func adImpression() {
    FakeApsClient.triggerImpressionAfterAdLoad = true

    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id")]
    ).jsonStringEncode()
    let adapter = AmazonBidLoadingAdapter()
    adapter.loadRewardedAd(for: config) { rewarded, error in
      #expect(rewarded != nil)
      #expect(error == nil)
      #expect(eventDelegate.reportImpressionInvokeCount == 0)
      return eventDelegate
    }
    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

  @Test("Report ad click")
  func adClick() {
    FakeApsClient.triggerAdClickAfterAdLoad = true

    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id")]
    ).jsonStringEncode()
    let adapter = AmazonBidLoadingAdapter()
    adapter.loadRewardedAd(for: config) { rewarded, error in
      #expect(rewarded != nil)
      #expect(error == nil)
      #expect(eventDelegate.reportClickInvokeCount == 0)
      return eventDelegate
    }
    #expect(eventDelegate.reportClickInvokeCount == 1)
  }

  @Test("Succeed to present an rewarded ad")
  func pressentRewarded_succeeds() async {
    FakeApsClient.showShouldSucceed = true

    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id")]
    ).jsonStringEncode()

    let adapter = AmazonBidLoadingAdapter()
    await confirmation("Ad load") { loaded in
      adapter.loadRewardedAd(for: config) { rewarded, error in
        defer {
          loaded()
        }
        #expect(rewarded != nil)
        #expect(error == nil)
        eventDelegate.rewardedAd = rewarded
        return eventDelegate
      }
    }

    await eventDelegate.rewardedAd?.present(from: UIViewController())
    #expect(eventDelegate.willPresentFullScreenViewInvokeCount == 1)
    #expect(eventDelegate.didDismissFullScreenViewInvokeCount == 1)
  }

  @Test("Fail to present an rewarded ad")
  func pressentRewarded_fails() async {
    FakeApsClient.showShouldSucceed = false

    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id")]
    ).jsonStringEncode()

    let adapter = AmazonBidLoadingAdapter()
    await confirmation("Ad load") { loaded in
      adapter.loadRewardedAd(for: config) { rewarded, error in
        defer {
          loaded()
        }
        #expect(rewarded != nil)
        #expect(error == nil)
        eventDelegate.rewardedAd = rewarded
        return eventDelegate
      }
    }

    await eventDelegate.rewardedAd?.present(from: UIViewController())
    #expect(eventDelegate.didFailToPresentError != nil)
  }

  @Test("Rewarded")
  func rewarded() async {
    FakeApsClient.showShouldSucceed = true

    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = try! AmazonBidLoadingAdapterResponseData(
      winners: [AmazonBidLoadingAdapterRequestData(adId: "id")]
    ).jsonStringEncode()

    let adapter = AmazonBidLoadingAdapter()
    await confirmation("Ad load") { loaded in
      adapter.loadRewardedAd(for: config) { rewarded, error in
        defer {
          loaded()
        }
        #expect(rewarded != nil)
        #expect(error == nil)
        eventDelegate.rewardedAd = rewarded
        return eventDelegate
      }
    }

    await eventDelegate.rewardedAd?.present(from: UIViewController())
    #expect(eventDelegate.didRewardUserInvokeCount == 1)
  }

}
