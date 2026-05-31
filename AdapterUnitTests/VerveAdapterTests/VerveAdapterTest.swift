import AdapterUnitTestKit
import HyBid
import XCTest

@testable import VerveAdapter

final class VerveAdapterTest: XCTestCase {

  override func tearDown() {
    HybidClientFactory.debugClient = nil
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = nil
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = nil
    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .unspecified
  }

  func testAdapterVersion() {
    let version = VerveAdapter.adapterVersion()

    XCTAssertGreaterThan(version.majorVersion, 0)
    XCTAssertLessThanOrEqual(version.majorVersion, 99)
    XCTAssertGreaterThanOrEqual(version.minorVersion, 0)
    XCTAssertLessThanOrEqual(version.minorVersion, 99)
    XCTAssertGreaterThanOrEqual(version.patchVersion, 0)
    XCTAssertLessThanOrEqual(version.patchVersion, 9999)
  }

  func testAdSDKVersion() {
    let version = VerveAdapter.adSDKVersion()

    XCTAssertGreaterThan(version.majorVersion, 0)
    XCTAssertLessThanOrEqual(version.majorVersion, 99)
    XCTAssertGreaterThanOrEqual(version.minorVersion, 0)
    XCTAssertLessThanOrEqual(version.minorVersion, 99)
    XCTAssertGreaterThanOrEqual(version.patchVersion, 0)
    XCTAssertLessThanOrEqual(version.patchVersion, 9999)
  }

  func testAdapterSetUp_succeeds() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["AppToken": "AppToken"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpWithConfiguration(VerveAdapter.self, serverConfiguration)
  }

  func testAdapterSetUp_fails_whenCOPPAIsTrue() {
    HybidClientFactory.debugClient = nil
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["AppToken": "AppToken"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      VerveAdapter.self, serverConfiguration,
      VerveAdapterError(errorCode: .childUser, description: "some error message").toNSError())
  }

  func testAdapterSetUp_fails_whenTFUAIsTrue() {
    HybidClientFactory.debugClient = nil
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["AppToken": "AppToken"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      VerveAdapter.self, serverConfiguration,
      VerveAdapterError(errorCode: .childUser, description: "some error message").toNSError())
  }

  func testAdapterSetUp_fails_whenAgeRestrictedTreatmentIsChild() {
    HybidClientFactory.debugClient = nil
    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .child

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["AppToken": "AppToken"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      VerveAdapter.self, serverConfiguration,
      VerveAdapterError(errorCode: .childUser, description: "some error message").toNSError())
  }

  func testAdapterSetUp_fails_whenAppTokenIsMissing() {
    HybidClientFactory.debugClient = nil

    let credentials = AUTKMediationCredentials()
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      VerveAdapter.self, serverConfiguration,
      VerveAdapterError(
        errorCode: .serverConfigurationMissingAppToken, description: "some error message"
      ).toNSError())
  }

  func testCollectionSignalsForBanner_succeeds_whenInvalidAdSize() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSizeInvalid

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs320x50() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 320, height: 50), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs300x250() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 300, height: 250), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs300x50() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 300, height: 50), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs320x480() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 320, height: 480), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs1024x768() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 1024, height: 768), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs768x1024() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 768, height: 1024), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs728x90() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 728, height: 90), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs160x600() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 160, height: 600), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs250x250() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 250, height: 250), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs300x600() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 300, height: 600), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs320x100() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 320, height: 100), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs480x320() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 480, height: 320), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignals_fails_whenCOPPAIsTrue() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()

    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertEqual(signals, "")
      let nsError = error as? NSError
      XCTAssertNotNil(nsError)
      XCTAssertEqual(nsError?.domain, "com.google.mediation.verve")
      XCTAssertEqual(nsError?.code, 102)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignals_fails_whenTFUAIsTrue() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()

    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertEqual(signals, "")
      let nsError = error as? NSError
      XCTAssertNotNil(nsError)
      XCTAssertEqual(nsError?.domain, "com.google.mediation.verve")
      XCTAssertEqual(nsError?.code, 102)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignals_fails_whenAgeRestrictedTreatmentIsChild() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()

    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .child

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertEqual(signals, "")
      let nsError = error as? NSError
      XCTAssertNotNil(nsError)
      XCTAssertEqual(nsError?.domain, "com.google.mediation.verve")
      XCTAssertEqual(nsError?.code, 102)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  // MARK: - loadBanner Tests under isChildUser

  func testLoadBanner_fails_whenCOPPAIsTrue() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "load banner")
    let config = AUTKMediationBannerAdConfiguration()

    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true

    adapter.loadBanner(for: config) { ad, error in
      XCTAssertNil(ad)
      let nsError = error as? NSError
      XCTAssertNotNil(nsError)
      XCTAssertEqual(nsError?.domain, "com.google.mediation.verve")
      XCTAssertEqual(nsError?.code, 102)
      expectation.fulfill()
      return nil
    }
    wait(for: [expectation])
  }

  func testLoadBanner_fails_whenTFUAIsTrue() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "load banner")
    let config = AUTKMediationBannerAdConfiguration()

    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true

    adapter.loadBanner(for: config) { ad, error in
      XCTAssertNil(ad)
      let nsError = error as? NSError
      XCTAssertNotNil(nsError)
      XCTAssertEqual(nsError?.domain, "com.google.mediation.verve")
      XCTAssertEqual(nsError?.code, 102)
      expectation.fulfill()
      return nil
    }
    wait(for: [expectation])
  }

  func testLoadBanner_fails_whenAgeRestrictedTreatmentIsChild() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "load banner")
    let config = AUTKMediationBannerAdConfiguration()

    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .child

    adapter.loadBanner(for: config) { ad, error in
      XCTAssertNil(ad)
      let nsError = error as? NSError
      XCTAssertNotNil(nsError)
      XCTAssertEqual(nsError?.domain, "com.google.mediation.verve")
      XCTAssertEqual(nsError?.code, 102)
      expectation.fulfill()
      return nil
    }
    wait(for: [expectation])
  }

  // MARK: - loadInterstitial Tests under isChildUser

  func testLoadInterstitial_fails_whenCOPPAIsTrue() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "load interstitial")
    let config = AUTKMediationInterstitialAdConfiguration()

    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true

    adapter.loadInterstitial(for: config) { ad, error in
      XCTAssertNil(ad)
      let nsError = error as? NSError
      XCTAssertNotNil(nsError)
      XCTAssertEqual(nsError?.domain, "com.google.mediation.verve")
      XCTAssertEqual(nsError?.code, 102)
      expectation.fulfill()
      return nil
    }
    wait(for: [expectation])
  }

  func testLoadInterstitial_fails_whenTFUAIsTrue() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "load interstitial")
    let config = AUTKMediationInterstitialAdConfiguration()

    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true

    adapter.loadInterstitial(for: config) { ad, error in
      XCTAssertNil(ad)
      let nsError = error as? NSError
      XCTAssertNotNil(nsError)
      XCTAssertEqual(nsError?.domain, "com.google.mediation.verve")
      XCTAssertEqual(nsError?.code, 102)
      expectation.fulfill()
      return nil
    }
    wait(for: [expectation])
  }

  func testLoadInterstitial_fails_whenAgeRestrictedTreatmentIsChild() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "load interstitial")
    let config = AUTKMediationInterstitialAdConfiguration()

    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .child

    adapter.loadInterstitial(for: config) { ad, error in
      XCTAssertNil(ad)
      let nsError = error as? NSError
      XCTAssertNotNil(nsError)
      XCTAssertEqual(nsError?.domain, "com.google.mediation.verve")
      XCTAssertEqual(nsError?.code, 102)
      expectation.fulfill()
      return nil
    }
    wait(for: [expectation])
  }

  // MARK: - loadRewardedAd Tests under isChildUser

  func testLoadRewardedAd_fails_whenCOPPAIsTrue() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "load rewarded")
    let config = AUTKMediationRewardedAdConfiguration()

    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true

    adapter.loadRewardedAd(for: config) { ad, error in
      XCTAssertNil(ad)
      let nsError = error as? NSError
      XCTAssertNotNil(nsError)
      XCTAssertEqual(nsError?.domain, "com.google.mediation.verve")
      XCTAssertEqual(nsError?.code, 102)
      expectation.fulfill()
      return nil
    }
    wait(for: [expectation])
  }

  func testLoadRewardedAd_fails_whenTFUAIsTrue() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "load rewarded")
    let config = AUTKMediationRewardedAdConfiguration()

    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true

    adapter.loadRewardedAd(for: config) { ad, error in
      XCTAssertNil(ad)
      let nsError = error as? NSError
      XCTAssertNotNil(nsError)
      XCTAssertEqual(nsError?.domain, "com.google.mediation.verve")
      XCTAssertEqual(nsError?.code, 102)
      expectation.fulfill()
      return nil
    }
    wait(for: [expectation])
  }

  func testLoadRewardedAd_fails_whenAgeRestrictedTreatmentIsChild() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "load rewarded")
    let config = AUTKMediationRewardedAdConfiguration()

    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .child

    adapter.loadRewardedAd(for: config) { ad, error in
      XCTAssertNil(ad)
      let nsError = error as? NSError
      XCTAssertNotNil(nsError)
      XCTAssertEqual(nsError?.domain, "com.google.mediation.verve")
      XCTAssertEqual(nsError?.code, 102)
      expectation.fulfill()
      return nil
    }
    wait(for: [expectation])
  }

  // MARK: - loadNativeAd Tests under isChildUser

  func testLoadNativeAd_fails_whenCOPPAIsTrue() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "load native")
    let config = AUTKMediationNativeAdConfiguration()

    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true

    adapter.loadNativeAd(for: config) { ad, error in
      XCTAssertNil(ad)
      let nsError = error as? NSError
      XCTAssertNotNil(nsError)
      XCTAssertEqual(nsError?.domain, "com.google.mediation.verve")
      XCTAssertEqual(nsError?.code, 102)
      expectation.fulfill()
      return nil
    }
    wait(for: [expectation])
  }

  func testLoadNativeAd_fails_whenTFUAIsTrue() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "load native")
    let config = AUTKMediationNativeAdConfiguration()

    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true

    adapter.loadNativeAd(for: config) { ad, error in
      XCTAssertNil(ad)
      let nsError = error as? NSError
      XCTAssertNotNil(nsError)
      XCTAssertEqual(nsError?.domain, "com.google.mediation.verve")
      XCTAssertEqual(nsError?.code, 102)
      expectation.fulfill()
      return nil
    }
    wait(for: [expectation])
  }

  func testLoadNativeAd_fails_whenAgeRestrictedTreatmentIsChild() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "load native")
    let config = AUTKMediationNativeAdConfiguration()

    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .child

    adapter.loadNativeAd(for: config) { ad, error in
      XCTAssertNil(ad)
      let nsError = error as? NSError
      XCTAssertNotNil(nsError)
      XCTAssertEqual(nsError?.domain, "com.google.mediation.verve")
      XCTAssertEqual(nsError?.code, 102)
      expectation.fulfill()
      return nil
    }
    wait(for: [expectation])
  }

}
