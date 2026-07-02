// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import AdapterUnitTestKit
import AppLovinSDK
import GoogleMobileAds
import OCMock
import XCTest

@testable import AppLovinAdapter

final class AppLovinWaterfallBannerTests: XCTestCase {

  private let sdkKey =
    "12345678901234567890123456789012345678901234567890123456789012345678901234567890123456"
  private let zoneId = "1234567890123456"

  nonisolated(unsafe) private var adapter: GADMediationAdapterAppLovin!
  nonisolated(unsafe) private var fakeClient: FakeAppLovinClient!
  nonisolated(unsafe) private var adMock: ALAd!

  override func setUp() {
    super.setUp()
    adapter = MainActor.assumeIsolated { GADMediationAdapterAppLovin() }
    fakeClient = MainActor.assumeIsolated { FakeAppLovinClient() }
    let client = fakeClient
    MainActor.assumeIsolated { AppLovinClientFactory.debugClient = client }
    adMock = (OCMockObject.mock(for: ALAd.self) as! ALAd)
  }

  override func tearDown() {
    MainActor.assumeIsolated { AppLovinClientFactory.debugClient = nil }
    let requestConfiguration = MobileAds.shared.requestConfiguration
    requestConfiguration.tagForChildDirectedTreatment = nil
    requestConfiguration.tagForUnderAgeOfConsent = nil
    super.tearDown()
  }

  @MainActor
  @discardableResult
  private func loadAdAndAssertLoadSuccess() -> AUTKMediationBannerAdEventDelegate {
    let config = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["sdkKey": sdkKey]
    config.credentials = credentials
    config.adSize = AdSizeBanner

    fakeClient.shouldAdLoadSucceed = true

    let eventDelegate = AUTKWaitAndAssertLoadBannerAd(adapter, config)
    XCTAssertNotNil(eventDelegate)
    return eventDelegate
  }

  // MARK: - Ad Load events

  @MainActor
  func testLoadBannerAdWithoutZoneId() {
    loadAdAndAssertLoadSuccess()
    XCTAssertTrue(fakeClient.loadBannerAdCalled)
  }

  @MainActor
  func testLoadBannerAdWithZoneId() {
    let config = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["sdkKey": sdkKey, "zone_id": zoneId]
    config.credentials = credentials
    config.adSize = AdSizeBanner

    fakeClient.shouldAdLoadSucceed = true

    let eventDelegate = AUTKWaitAndAssertLoadBannerAd(adapter, config)
    XCTAssertNotNil(eventDelegate)
    XCTAssertTrue(fakeClient.loadBannerAdCalled)
  }

  @MainActor
  func testLoadFailureIfAppLovinFailsToLoad() {
    let config = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["sdkKey": sdkKey, "zone_id": zoneId]
    config.credentials = credentials
    config.adSize = AdSizeBanner

    fakeClient.shouldAdLoadSucceed = false
    fakeClient.errorCodeToFailWith = 1001

    let expectedError = NSError(
      domain: GADMAdapterAppLovinSDKErrorDomain,
      code: 1001,
      userInfo: nil
    )

    AUTKWaitAndAssertLoadBannerAdFailure(adapter, config, expectedError)
  }

  @MainActor
  func testLoadFailureIfSizeIsNotSupportedByAppLovin() {
    let config = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["sdkKey": sdkKey, "zone_id": zoneId]
    config.credentials = credentials
    config.adSize = AdSizeSkyscraper

    let expectedError = NSError(
      domain: GADMAdapterAppLovinErrorDomain,
      code: GADMAdapterAppLovinErrorCode.bannerSizeMismatch.rawValue,
      userInfo: nil
    )

    AUTKWaitAndAssertLoadBannerAdFailure(adapter, config, expectedError)
  }

  @MainActor
  func testLoadFailureForInvalidAppLovinZoneId() {
    let config = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    let invalidZoneID = "12"
    credentials.settings = ["sdkKey": sdkKey, "zone_id": invalidZoneID]
    config.credentials = credentials

    let expectedError = NSError(
      domain: GADMAdapterAppLovinErrorDomain,
      code: GADMAdapterAppLovinErrorCode.invalidServerParameters.rawValue,
      userInfo: nil
    )

    AUTKWaitAndAssertLoadBannerAdFailure(adapter, config, expectedError)
  }

  @MainActor
  func testLoadFailureIfAppLovinSdkKeyIsAbsent() {
    let config = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["zone_id": zoneId]
    config.credentials = credentials

    let expectedError = NSError(
      domain: GADMAdapterAppLovinErrorDomain,
      code: GADMAdapterAppLovinErrorCode.missingSDKKey.rawValue,
      userInfo: nil
    )

    AUTKWaitAndAssertLoadBannerAdFailure(adapter, config, expectedError)
  }

  // MARK: - Effects of child tag and under-age tag on ad load

  @MainActor
  func testLoadSuccessIfChildTagIsNilAndUnderAgeTagIsNil() {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = nil
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = nil

    loadAdAndAssertLoadSuccess()
  }

  @MainActor
  func testLoadSuccessIfChildTagIsNilAndUnderAgeTagIsFalse() {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = nil
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = false

    loadAdAndAssertLoadSuccess()
  }

  @MainActor
  func testLoadFailureIfChildTagIsNilAndUnderAgeTagIsTrue() {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = nil
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true
    let config = AUTKMediationBannerAdConfiguration()

    let expectedError = NSError(
      domain: GADMAdapterAppLovinErrorDomain,
      code: GADMAdapterAppLovinErrorCode.childUser.rawValue,
      userInfo: nil
    )
    AUTKWaitAndAssertLoadBannerAdFailure(adapter, config, expectedError)
  }

  @MainActor
  func testLoadSuccessIfChildTagIsFalseAndUnderAgeTagIsNil() {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = false
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = nil

    loadAdAndAssertLoadSuccess()
  }

  @MainActor
  func testLoadSuccessIfChildTagIsFalseAndUnderAgeTagIsFalse() {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = false
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = false

    loadAdAndAssertLoadSuccess()
  }

  @MainActor
  func testLoadFailureIfChildTagIsFalseAndUnderAgeTagIsTrue() {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = false
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true
    let config = AUTKMediationBannerAdConfiguration()

    let expectedError = NSError(
      domain: GADMAdapterAppLovinErrorDomain,
      code: GADMAdapterAppLovinErrorCode.childUser.rawValue,
      userInfo: nil
    )
    AUTKWaitAndAssertLoadBannerAdFailure(adapter, config, expectedError)
  }

  @MainActor
  func testLoadFailureIfChildTagIsTrueAndUnderAgeTagIsNil() {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = nil
    let config = AUTKMediationBannerAdConfiguration()

    let expectedError = NSError(
      domain: GADMAdapterAppLovinErrorDomain,
      code: GADMAdapterAppLovinErrorCode.childUser.rawValue,
      userInfo: nil
    )
    AUTKWaitAndAssertLoadBannerAdFailure(adapter, config, expectedError)
  }

  @MainActor
  func testLoadFailureIfChildTagIsTrueAndUnderAgeTagIsFalse() {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = false
    let config = AUTKMediationBannerAdConfiguration()

    let expectedError = NSError(
      domain: GADMAdapterAppLovinErrorDomain,
      code: GADMAdapterAppLovinErrorCode.childUser.rawValue,
      userInfo: nil
    )
    AUTKWaitAndAssertLoadBannerAdFailure(adapter, config, expectedError)
  }

  @MainActor
  func testLoadFailureIfChildTagIsTrueAndUnderAgeTagIsTrue() {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true
    let config = AUTKMediationBannerAdConfiguration()

    let expectedError = NSError(
      domain: GADMAdapterAppLovinErrorDomain,
      code: GADMAdapterAppLovinErrorCode.childUser.rawValue,
      userInfo: nil
    )
    AUTKWaitAndAssertLoadBannerAdFailure(adapter, config, expectedError)
  }

  // MARK: - Ad View

  @MainActor
  func testGetView() {
    let eventDelegate = loadAdAndAssertLoadSuccess()
    XCTAssertEqual(eventDelegate.bannerAd?.view, fakeClient.dummyView)
  }

  // MARK: - Ad Lifecycle events

  @MainActor
  func testAdDisplayed() {
    let eventDelegate = loadAdAndAssertLoadSuccess()

    fakeClient.capturedDelegate?.ad(adMock, wasDisplayedIn: fakeClient.dummyView)

    XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1)
  }

  @MainActor
  func testAdFailedToDisplay() {
    let eventDelegate = loadAdAndAssertLoadSuccess()

    fakeClient.capturedDelegate?.ad?(
      adMock,
      didFailToDisplayIn: fakeClient.dummyView,
      withError: ALAdViewDisplayErrorCode(rawValue: 1005) ?? .unspecified
    )

    let presentError = eventDelegate.didFailToPresentError as NSError?
    XCTAssertEqual(presentError?.code, 1005)
    XCTAssertEqual(presentError?.domain, GADMAdapterAppLovinSDKErrorDomain)
  }

  @MainActor
  func testAdClick() {
    let eventDelegate = loadAdAndAssertLoadSuccess()

    fakeClient.capturedDelegate?.ad(adMock, wasClickedIn: fakeClient.dummyView)

    XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1)
  }

  @MainActor
  func testDidPresentFullscreen() {
    let eventDelegate = loadAdAndAssertLoadSuccess()

    fakeClient.capturedDelegate?.ad?(
      adMock,
      didPresentFullscreenFor: fakeClient.dummyView
    )

    XCTAssertEqual(eventDelegate.willPresentFullScreenViewInvokeCount, 1)
  }

  @MainActor
  func testWillDismissFullscreen() {
    let eventDelegate = loadAdAndAssertLoadSuccess()

    fakeClient.capturedDelegate?.ad?(
      adMock,
      willDismissFullscreenFor: fakeClient.dummyView
    )

    XCTAssertEqual(eventDelegate.willDismissFullScreenViewInvokeCount, 1)
  }

  @MainActor
  func testDidDismissFullscreen() {
    let eventDelegate = loadAdAndAssertLoadSuccess()

    fakeClient.capturedDelegate?.ad?(
      adMock,
      didDismissFullscreenFor: fakeClient.dummyView
    )

    XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1)
  }

  @MainActor
  func testUnhandledEventsResultInNoCrash() {
    loadAdAndAssertLoadSuccess()

    fakeClient.capturedDelegate?.ad(adMock, wasHiddenIn: fakeClient.dummyView)
    fakeClient.capturedDelegate?.ad?(
      adMock,
      willLeaveApplicationFor: fakeClient.dummyView
    )
  }

}
