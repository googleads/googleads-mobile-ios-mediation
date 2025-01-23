import AdapterUnitTestKit
import GoogleMobileAds
import Testing

@testable import AmazonAdapter

@Suite("Amazon adapter information")
struct AmazonAdapterInformationTests {

  init() {
    AmazonBidLoadingAdapter.setApsClient(apsClient: FakeApsClient())
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

  let apsClient: FakeApsClient

  init() {
    apsClient = FakeApsClient()
    AmazonBidLoadingAdapter.setApsClient(apsClient: apsClient)
  }

  @Test("Successful adapter setup with one App ID.")
  func setUp_succeeds_whenOneAppIdExistsInServerConfiguration() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["app_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    AmazonBidLoadingAdapter.setUpWith(serverConfiguration) { error in
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

    AmazonBidLoadingAdapter.setUpWith(serverConfiguration) { error in
      #expect(error == nil)
    }
  }

  @Test("The extra's test bits validation")
  func setUp_success_whenTestModesAreEnabled() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["app_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AmazonBidLoadingAdapterExtras.testMode = true
    AmazonBidLoadingAdapterExtras.gdprRegionTestMode = true
    AmazonBidLoadingAdapterExtras.skAdNetworkTestMode = true

    AmazonBidLoadingAdapter.setUpWith(serverConfiguration) { error in
      #expect(error == nil)
    }
  }

  @Test("Unsuccessful adpater setup for missing app_id")
  func setUp_failsWithInvalidServerParametersError_whenServerConfigurationDoesNotContainAppId() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [:]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    AmazonBidLoadingAdapter.setUpWith(serverConfiguration) { error in
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
    apsClient.initializeShouldSucceed = false
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["app_id": "testid"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    AmazonBidLoadingAdapter.setUpWith(serverConfiguration) { error in
      let error = try! #require(error as NSError?)
      #expect(error.domain == AmazonBidLoadingAdapterConstants.apsSdkErrorDomain)
      #expect(error.localizedDescription.count > 0)
      #expect(error.localizedFailureReason!.count > 0)
    }
  }

}
