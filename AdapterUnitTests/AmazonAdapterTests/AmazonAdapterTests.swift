import AdapterUnitTestKit
import DTBiOSSDK
import GoogleMobileAds
import Testing

@testable import AmazonAdapter

@Suite("Amazon adapter information")
struct AmazonAdapterInformationTests {

  init() {
    FakeApsClient.resetTestFlags()
    setenv("FAKE_APS_CLIENT_CLASS_NAME", "AmazonAdapterTests.FakeApsClient", 1)
  }

  @Test("Adapter version validation")
  func adapterVersion_validates() {
    let adapterVersion = AmazonBidLoadingAdapter.adapterVersion()
    #expect(adapterVersion.majorVersion > 0)
    #expect(adapterVersion.minorVersion >= 0)
    #expect(adapterVersion.patchVersion >= 0)
  }

  @Test("Ad SDK version validation")
  func adSdkVersion_validates() {
    let adSdkVersion = AmazonBidLoadingAdapter.adSDKVersion()
    #expect(adSdkVersion.majorVersion > 0)
    #expect(adSdkVersion.minorVersion >= 0)
    #expect(adSdkVersion.patchVersion >= 0)
  }

  @Test("Extra class validation.")
  func extrasClass_validates() {
    #expect(AmazonBidLoadingAdapter.networkExtrasClass() == AmazonBidLoadingAdapterExtras.self)
  }

}

@Suite("Amazon adapter setup")
struct AmazonAdapterSetUpTests {

  init() {
    FakeApsClient.resetTestFlags()
    setenv("FAKE_APS_CLIENT_CLASS_NAME", "AmazonAdapterTests.FakeApsClient", 1)
  }

  @Test("Successful adapter setup with one App ID.")
  func setUp_succeeds_whenOneAppIdExistsInServerConfiguration() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["app_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    AmazonBidLoadingAdapter.setUp(with: serverConfiguration) { error in
      #expect(error == nil)
    }
  }

  @Test("Successful adapter setup with multiple App IDs.")
  func setUp_succeeds_whenMultipleUniqueAppIdsExistInServerConfiguration() {
    let credentials1 = AUTKMediationCredentials()
    credentials1.settings = ["app_id": "test_id_1"]
    let credentials2 = AUTKMediationCredentials()
    credentials2.settings = ["app_id": "test_id_2"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials1, credentials2]

    AmazonBidLoadingAdapter.setUp(with: serverConfiguration) { error in
      #expect(error == nil)
    }
  }

  @Test("The extra's test bits validation")
  func setUp_success_whenTestModesAreEnabled() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["app_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    let initConfig = APSInitConfig()
    initConfig.testMode = true
    initConfig.gdprRegionTestMode = true
    initConfig.skAdNetworkTestMode = true
    AmazonBidLoadingAdapterExtras.apsInitConfig = initConfig

    AmazonBidLoadingAdapter.setUp(with: serverConfiguration) { error in
      #expect(error == nil)
    }
  }

  @Test("Unsuccessful adpater setup for missing app_id")
  func setUp_failsWithInvalidServerParametersError_whenServerConfigurationDoesNotContainAppId() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [:]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    AmazonBidLoadingAdapter.setUp(with: serverConfiguration) { error in
      let error = try! #require(error as NSError?)
      #expect(error.domain == AmazonBidLoadingAdapterError.domain)
      #expect(
        error.code == AmazonBidLoadingAdapterError.Category.serverConfigurationMissingAppId.rawValue
      )
      #expect(error.localizedDescription.count > 0)
      #expect(error.localizedFailureReason!.count > 0)
    }
  }

  @Test("Unsuccessful adpater setup for a APS SDK init error")
  func setUp_failsWithApsSdkError_whenApsSdkInitializationCompletesWithError() {
    FakeApsClient.initializeShouldSucceed = false
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["app_id": "testid"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    AmazonBidLoadingAdapter.setUp(with: serverConfiguration) { error in
      let error = try! #require(error as NSError?)
      #expect(error.domain == AmazonBidLoadingAdapterConstants.apsSdkErrorDomain)
      #expect(error.localizedDescription.count > 0)
      #expect(error.localizedFailureReason!.count > 0)
    }
  }

}

@Suite("Amazon adapter signals collection")
struct AmazonAdapterCollectSignalsTests {

  init() {
    FakeApsClient.resetTestFlags()
    setenv("FAKE_APS_CLIENT_CLASS_NAME", "AmazonAdapterTests.FakeApsClient", 1)
  }

  @Test("Successful signals collection for banner ad")
  func collectSignals_succeeds_whenAdFormatIsBanner() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "testid", "slot_width": "320", "slot_height": "50"]
    credentials.format = .banner
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations
    let expectedSize = CGSize(width: 320, height: 50)
    requestParams.adSize = AdSizeBanner

    let adapter = AmazonBidLoadingAdapter()
    await confirmation("wait for singals collection") { signalsLoaded in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(signals != nil)
          #expect(error == nil)
          let requestDataDict = signals?.toJsonDictionary()
          #expect(requestDataDict != nil)
          #expect(requestDataDict!["winning_bid_price_encoded"] != nil)
          #expect(requestDataDict!["ad_id"] != nil)
          #expect(requestDataDict!["width"] as! Int == Int(expectedSize.width))
          #expect(requestDataDict!["height"] as! Int == Int(expectedSize.height))
          signalsLoaded()
          continuation.resume()
        }
      }
    }
  }

  @Test("Successful signals collection for MREC ad")
  func collectSignals_succeeds_whenAdFormatIsMrec() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "testid", "slot_width": "300", "slot_height": "250"]
    credentials.format = .banner
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations
    let expectedSize = CGSize(width: 300, height: 250)
    requestParams.adSize = AdSizeMediumRectangle

    let adapter = AmazonBidLoadingAdapter()
    await confirmation("wait for singals collection") { signalsLoaded in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(signals != nil)
          #expect(error == nil)
          let requestDataDict = signals?.toJsonDictionary()
          #expect(requestDataDict != nil)
          #expect(requestDataDict!["winning_bid_price_encoded"] != nil)
          #expect(requestDataDict!["ad_id"] != nil)
          #expect(requestDataDict!["width"] as! Int == Int(expectedSize.width))
          #expect(requestDataDict!["height"] as! Int == Int(expectedSize.height))
          signalsLoaded()
          continuation.resume()
        }
      }
    }
  }

  @Test("Successful signals collection for leaderboard ad")
  func collectSignals_succeeds_whenAdFormatIsLeaderboard() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "testid", "slot_width": "728", "slot_height": "90"]
    credentials.format = .banner
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations
    let expectedSize = CGSize(width: 728, height: 90)
    requestParams.adSize = AdSizeLeaderboard

    let adapter = AmazonBidLoadingAdapter()
    await confirmation("wait for singals collection") { signalsLoaded in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(signals != nil)
          #expect(error == nil)
          let requestDataDict = signals?.toJsonDictionary()
          #expect(requestDataDict != nil)
          #expect(requestDataDict!["winning_bid_price_encoded"] != nil)
          #expect(requestDataDict!["ad_id"] != nil)
          #expect(requestDataDict!["width"] as! Int == Int(expectedSize.width))
          #expect(requestDataDict!["height"] as! Int == Int(expectedSize.height))
          signalsLoaded()
          continuation.resume()
        }
      }
    }
  }

  @Test("Successful signals collection for interstitial ad")
  func collectSignals_succeeds_whenAdFormatIsInterstitial() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "testid"]
    credentials.format = .interstitial
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations
    requestParams.adSize = AdSizeInvalid

    let adapter = AmazonBidLoadingAdapter()
    await confirmation("wait for singals collection") { signalsLoaded in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(signals != nil)
          #expect(error == nil)
          let requestDataDict = signals?.toJsonDictionary()
          #expect(requestDataDict != nil)
          #expect(requestDataDict!["winning_bid_price_encoded"] != nil)
          #expect(requestDataDict!["ad_id"] != nil)
          #expect(requestDataDict!["width"] as! Int == 0)
          #expect(requestDataDict!["height"] as! Int == 0)
          signalsLoaded()
          continuation.resume()
        }
      }
    }
  }

  @Test("Successful signals collection for rewarded ad")
  func collectSignals_succeeds_whenAdFormatIsRewarded() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "testid"]
    credentials.format = .rewarded
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations
    requestParams.adSize = AdSizeInvalid

    let adapter = AmazonBidLoadingAdapter()
    await confirmation("wait for singals collection") { signalsLoaded in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(signals != nil)
          #expect(error == nil)
          let requestDataDict = signals?.toJsonDictionary()
          #expect(requestDataDict != nil)
          #expect(requestDataDict!["winning_bid_price_encoded"] != nil)
          #expect(requestDataDict!["ad_id"] != nil)
          #expect(requestDataDict!["width"] as! Int == 0)
          #expect(requestDataDict!["height"] as! Int == 0)
          signalsLoaded()
          continuation.resume()
        }
      }
    }
  }

  @Test("Successful signals collection with multiple slot IDs.")
  func collectSignals_succeedsWithMultipleUniqueSlotIds() async {
    let credentials1 = AUTKMediationCredentials()
    credentials1.settings = ["slot_id": "testid1", "slot_width": "1", "slot_height": "1"]
    let credentials2 = AUTKMediationCredentials()
    credentials2.settings = ["slot_id": "testid2", "slot_width": "320", "slot_height": "50"]
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials1, credentials2]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations
    let expectedSize = CGSize(width: 320, height: 50)
    requestParams.adSize = AdSize(size: expectedSize, flags: 0)

    let adapter = AmazonBidLoadingAdapter()
    await confirmation("wait for singals collection") { signalsLoaded in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(signals != nil)
          #expect(error == nil)
          let requestDataDict = signals?.toJsonDictionary()
          #expect(requestDataDict != nil)
          #expect(requestDataDict!["winning_bid_price_encoded"] != nil)
          #expect(requestDataDict!["ad_id"] != nil)
          #expect(requestDataDict!["width"] as! Int == Int(expectedSize.width))
          #expect(requestDataDict!["height"] as! Int == Int(expectedSize.height))
          #expect(requestDataDict!["adapter_error"] == nil)
          #expect(requestDataDict!["third_party_sdk_error"] == nil)
          signalsLoaded()
          continuation.resume()
        }
      }
    }
  }

  @Test("Unsuccessful signals collection for unsupported ad format")
  func collectSignals_fails_whenRequestIsForUnsupportedAdFormat() async {
    let credentials1 = AUTKMediationCredentials()
    credentials1.settings = ["slot_id": "testid1"]
    credentials1.format = .native
    let credentials2 = AUTKMediationCredentials()
    credentials2.settings = ["slot_id": "testid2"]
    credentials2.format = .native
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials1, credentials2]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations
    let expectedSize = AdSizeInvalid.size
    requestParams.adSize = AdSize(size: expectedSize, flags: 0)

    let adapter = AmazonBidLoadingAdapter()
    await confirmation("wait for singals collection") { signalsLoaded in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(signals != nil)
          #expect(error == nil)
          let requestDataDict = signals?.toJsonDictionary()
          #expect(requestDataDict != nil)
          #expect(requestDataDict!["winning_bid_price_encoded"] == nil)
          #expect(requestDataDict!["ad_id"] == nil)
          #expect(requestDataDict!["width"] == nil)
          #expect(requestDataDict!["height"] == nil)
          #expect(requestDataDict!["adapter_error"] as? String == "UNSUPPORTED_AD_FORMAT")
          #expect(requestDataDict!["third_party_sdk_error"] == nil)
          signalsLoaded()
          continuation.resume()
        }
      }
    }
  }

  @Test("Unsuccessful signals collection for missing a slot id")
  func collectSignals_fails_whenRequestParametersDoesNotContainASlotId() async {
    let credentials = AUTKMediationCredentials()
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations
    let expectedSize = CGSize(width: 100, height: 100)
    requestParams.adSize = AdSize(size: expectedSize, flags: 0)

    let adapter = AmazonBidLoadingAdapter()
    await confirmation("wait for singals collection") { signalsLoaded in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(signals != nil)
          #expect(error == nil)
          let requestDataDict = signals?.toJsonDictionary()
          #expect(requestDataDict != nil)
          #expect(requestDataDict!["winning_bid_price_encoded"] == nil)
          #expect(requestDataDict!["ad_id"] == nil)
          #expect(requestDataDict!["width"] == nil)
          #expect(requestDataDict!["height"] == nil)
          #expect(requestDataDict!["adapter_error"] as? String == "MISSING_SLOT_ID")
          #expect(requestDataDict!["third_party_sdk_error"] == nil)
          signalsLoaded()
          continuation.resume()
        }
      }
    }
  }

  @Test("Unsuccessful signals collection for containing an empty slot id")
  func collectSignals_fails_whenRequestParametersContainsAnEmptySlotId() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": ""]
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations
    let expectedSize = CGSize(width: 100, height: 100)
    requestParams.adSize = AdSize(size: expectedSize, flags: 0)

    let adapter = AmazonBidLoadingAdapter()
    await confirmation("wait for singals collection") { signalsLoaded in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(signals != nil)
          #expect(error == nil)
          let requestDataDict = signals?.toJsonDictionary()
          #expect(requestDataDict != nil)
          #expect(requestDataDict!["winning_bid_price_encoded"] == nil)
          #expect(requestDataDict!["ad_id"] == nil)
          #expect(requestDataDict!["width"] == nil)
          #expect(requestDataDict!["height"] == nil)
          #expect(requestDataDict!["adapter_error"] as? String == "MISSING_SLOT_ID")
          #expect(requestDataDict!["third_party_sdk_error"] == nil)
          signalsLoaded()
          continuation.resume()
        }
      }
    }
  }

  @Test("Unsuccessful signals collection for APS failing load an APS ad")
  func collectSignals_fails_whenApsSdkFailsToLoadAnApsAd() async {
    FakeApsClient.signalsCollectionShouldSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "testid", "slot_width": "320", "slot_height": "50"]
    credentials.format = .banner
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations
    let expectedSize = CGSize(width: 320, height: 50)
    requestParams.adSize = AdSize(size: expectedSize, flags: 0)

    let adapter = AmazonBidLoadingAdapter()
    await confirmation("wait for singals collection") { signalsLoaded in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(signals != nil)
          #expect(error == nil)
          let requestDataDict = signals?.toJsonDictionary()
          #expect(requestDataDict != nil)
          #expect(requestDataDict!["winning_bid_price_encoded"] == nil)
          #expect(requestDataDict!["ad_id"] == nil)
          #expect(requestDataDict!["width"] == nil)
          #expect(requestDataDict!["height"] == nil)
          #expect(requestDataDict!["adapter_error"] as? String == "3P_SDK_ERROR")
          #expect(requestDataDict!["third_party_sdk_error"] as? String == "12345")
          signalsLoaded()
          continuation.resume()
        }
      }
    }
  }

}

extension String {

  fileprivate func toJsonDictionary() -> [String: Any]? {
    if let jsonData = self.data(using: .utf8) {
      do {
        let dictionary = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        return dictionary
      } catch {
        print("Error converting JSON string to dictionary: \(error)")
        return nil
      }
    } else {
      print("Invalid JSON string")
      return nil
    }
  }

}
