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
import Testing
import XCTest

@testable import AppLovinAdapter

@MainActor
@Suite("AppLovin Waterfall Banner Tests", .serialized)
final class AppLovinWaterfallBannerTests {
  private let fakeClient: FakeAppLovinClient
  private let adapter: GADMediationAdapterAppLovin

  private static let sdkKey =
    "12345678901234567890123456789012345678901234567890123456789012345678901234567890123456"
  private static let zoneId = "1234567890123456"

  init() {
    fakeClient = FakeAppLovinClient()
    AppLovinClientFactory.debugClient = fakeClient
    adapter = GADMediationAdapterAppLovin()
  }

  deinit {
    AppLovinClientFactory.debugClient = nil

    // Reset child-directed and under-age tags.
    let requestConfiguration = MobileAds.shared.requestConfiguration
    requestConfiguration.tagForChildDirectedTreatment = nil
    requestConfiguration.tagForUnderAgeOfConsent = nil
  }

  private func loadAdAndAssertLoadSuccess(
    zoneId: String? = nil,
    sdkKey: String = sdkKey
  ) -> AUTKMediationBannerAdEventDelegate {
    let adConfig = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    var settings: [String: Any] = ["sdkKey": sdkKey]
    if let zoneId = zoneId {
      settings["zone_id"] = zoneId
    }
    credentials.settings = settings
    adConfig.credentials = credentials
    adConfig.adSize = AdSizeBanner

    let eventDelegate = AUTKWaitAndAssertLoadBannerAd(adapter, adConfig)
    return eventDelegate
  }

  private func loadAdAndAssertLoadFailure(
    zoneId: String? = nil,
    sdkKey: String? = sdkKey,
    adSize: AdSize = AdSizeBanner,
    expectedError: NSError
  ) {
    let adConfig = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    var settings: [String: Any] = [:]
    if let sdkKey = sdkKey {
      settings["sdkKey"] = sdkKey
    }
    if let zoneId = zoneId {
      settings["zone_id"] = zoneId
    }
    credentials.settings = settings
    adConfig.credentials = credentials
    adConfig.adSize = adSize

    AUTKWaitAndAssertLoadBannerAdFailure(adapter, adConfig, expectedError)
  }

  @Test
  func loadBannerAdWithoutZoneId() {
    _ = loadAdAndAssertLoadSuccess()
  }

  @Test
  func loadBannerAdWithZoneId() {
    _ = loadAdAndAssertLoadSuccess(zoneId: Self.zoneId)
  }

  @Test
  func loadFailureIfAppLovinFailsToLoad() {
    fakeClient.errorToReturn = 1001
    let expectedError = NSError(
      domain: GADMAdapterAppLovinConstant.sdkErrorDomain,
      code: 1001,
      userInfo: nil
    )
    loadAdAndAssertLoadFailure(zoneId: Self.zoneId, expectedError: expectedError)
  }

  @Test
  func loadFailureIfSizeIsNotSupportedByAppLovin() {
    let expectedError = NSError(
      domain: GADMAdapterAppLovinConstant.errorDomain,
      code: GADMAdapterAppLovinErrorCode.bannerSizeMismatch.rawValue,
      userInfo: nil
    )
    loadAdAndAssertLoadFailure(adSize: AdSizeSkyscraper, expectedError: expectedError)
  }

  @Test
  func loadFailureForInvalidAppLovinZoneId() {
    let invalidZoneID = "12"  // AppLovin expects 16 chars
    let expectedError = NSError(
      domain: GADMAdapterAppLovinConstant.errorDomain,
      code: GADMAdapterAppLovinErrorCode.invalidServerParameters.rawValue,
      userInfo: nil
    )
    loadAdAndAssertLoadFailure(zoneId: invalidZoneID, expectedError: expectedError)
  }

  @Test
  func loadFailureIfAppLovinSdkKeyIsAbsent() {
    let expectedError = NSError(
      domain: GADMAdapterAppLovinConstant.errorDomain,
      code: GADMAdapterAppLovinErrorCode.missingSDKKey.rawValue,
      userInfo: nil
    )
    loadAdAndAssertLoadFailure(sdkKey: nil, expectedError: expectedError)
  }

  // MARK: - Child tag and under-age tag tests

  @Test
  func loadSuccessIfChildTagIsNilAndUnderAgeTagIsNil() {
    let requestConfiguration = MobileAds.shared.requestConfiguration
    requestConfiguration.tagForChildDirectedTreatment = nil
    requestConfiguration.tagForUnderAgeOfConsent = nil
    _ = loadAdAndAssertLoadSuccess()
  }

  @Test
  func loadSuccessIfChildTagIsNilAndUnderAgeTagIsFalse() {
    let requestConfiguration = MobileAds.shared.requestConfiguration
    requestConfiguration.tagForChildDirectedTreatment = nil
    requestConfiguration.tagForUnderAgeOfConsent = false
    _ = loadAdAndAssertLoadSuccess()
  }

  @Test
  func loadFailureIfChildTagIsNilAndUnderAgeTagIsTrue() {
    let requestConfiguration = MobileAds.shared.requestConfiguration
    requestConfiguration.tagForChildDirectedTreatment = nil
    requestConfiguration.tagForUnderAgeOfConsent = true

    let expectedError = NSError(
      domain: GADMAdapterAppLovinConstant.errorDomain,
      code: GADMAdapterAppLovinErrorCode.childUser.rawValue,
      userInfo: nil
    )
    loadAdAndAssertLoadFailure(expectedError: expectedError)
  }

  @Test
  func loadSuccessIfChildTagIsFalseAndUnderAgeTagIsNil() {
    let requestConfiguration = MobileAds.shared.requestConfiguration
    requestConfiguration.tagForChildDirectedTreatment = false
    requestConfiguration.tagForUnderAgeOfConsent = nil
    _ = loadAdAndAssertLoadSuccess()
  }

  @Test
  func loadSuccessIfChildTagIsFalseAndUnderAgeTagIsFalse() {
    let requestConfiguration = MobileAds.shared.requestConfiguration
    requestConfiguration.tagForChildDirectedTreatment = false
    requestConfiguration.tagForUnderAgeOfConsent = false
    _ = loadAdAndAssertLoadSuccess()
  }

  @Test
  func loadFailureIfChildTagIsFalseAndUnderAgeTagIsTrue() {
    let requestConfiguration = MobileAds.shared.requestConfiguration
    requestConfiguration.tagForChildDirectedTreatment = false
    requestConfiguration.tagForUnderAgeOfConsent = true

    let expectedError = NSError(
      domain: GADMAdapterAppLovinConstant.errorDomain,
      code: GADMAdapterAppLovinErrorCode.childUser.rawValue,
      userInfo: nil
    )
    loadAdAndAssertLoadFailure(expectedError: expectedError)
  }

  @Test
  func loadFailureIfChildTagIsTrueAndUnderAgeTagIsNil() {
    let requestConfiguration = MobileAds.shared.requestConfiguration
    requestConfiguration.tagForChildDirectedTreatment = true
    requestConfiguration.tagForUnderAgeOfConsent = nil

    let expectedError = NSError(
      domain: GADMAdapterAppLovinConstant.errorDomain,
      code: GADMAdapterAppLovinErrorCode.childUser.rawValue,
      userInfo: nil
    )
    loadAdAndAssertLoadFailure(expectedError: expectedError)
  }

  @Test
  func loadFailureIfChildTagIsTrueAndUnderAgeTagIsFalse() {
    let requestConfiguration = MobileAds.shared.requestConfiguration
    requestConfiguration.tagForChildDirectedTreatment = true
    requestConfiguration.tagForUnderAgeOfConsent = false

    let expectedError = NSError(
      domain: GADMAdapterAppLovinConstant.errorDomain,
      code: GADMAdapterAppLovinErrorCode.childUser.rawValue,
      userInfo: nil
    )
    loadAdAndAssertLoadFailure(expectedError: expectedError)
  }

  @Test
  func loadFailureIfChildTagIsTrueAndUnderAgeTagIsTrue() {
    let requestConfiguration = MobileAds.shared.requestConfiguration
    requestConfiguration.tagForChildDirectedTreatment = true
    requestConfiguration.tagForUnderAgeOfConsent = true

    let expectedError = NSError(
      domain: GADMAdapterAppLovinConstant.errorDomain,
      code: GADMAdapterAppLovinErrorCode.childUser.rawValue,
      userInfo: nil
    )
    loadAdAndAssertLoadFailure(expectedError: expectedError)
  }

  // MARK: - Ad View

  @Test
  func getView() throws {
    let eventDelegate = loadAdAndAssertLoadSuccess()
    let fakeAdView = fakeClient.createdAdViews.first!
    let bannerAd = try #require(eventDelegate.bannerAd)
    #expect(bannerAd.view === fakeAdView.view)
  }

  // MARK: - Ad Lifecycle events

  @Test
  func adDisplayed() {
    let eventDelegate = loadAdAndAssertLoadSuccess()
    let fakeAdView = fakeClient.createdAdViews.first!
    let delegate = fakeAdView.adDisplayDelegate!

    let fakeAd = makeFakeALAd()
    delegate.ad(fakeAd, wasDisplayedIn: fakeAdView.view)

    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

  @Test
  func adFailedToDisplay() throws {
    let eventDelegate = loadAdAndAssertLoadSuccess()
    let fakeAdView = fakeClient.createdAdViews.first!
    let delegate = fakeAdView.adEventDelegate!

    let fakeAd = makeFakeALAd()
    // Fictitious AppLovin error code 1005
    delegate.ad?(
      fakeAd,
      didFailToDisplayIn: fakeAdView.fakeALAdView,
      withError: ALAdViewDisplayErrorCode(rawValue: 1005)!
    )

    let error = try #require(eventDelegate.didFailToPresentError as NSError?)
    #expect(error.code == 1005)
    #expect(error.domain == GADMAdapterAppLovinConstant.sdkErrorDomain)
  }

  @Test
  func adClick() {
    let eventDelegate = loadAdAndAssertLoadSuccess()
    let fakeAdView = fakeClient.createdAdViews.first!
    let delegate = fakeAdView.adDisplayDelegate!

    let fakeAd = makeFakeALAd()
    delegate.ad(fakeAd, wasClickedIn: fakeAdView.view)

    #expect(eventDelegate.reportClickInvokeCount == 1)
  }

  @Test
  func didPresentFullscreen() {
    let eventDelegate = loadAdAndAssertLoadSuccess()
    let fakeAdView = fakeClient.createdAdViews.first!
    let delegate = fakeAdView.adEventDelegate!

    let fakeAd = makeFakeALAd()
    delegate.ad?(fakeAd, didPresentFullscreenFor: fakeAdView.fakeALAdView)

    #expect(eventDelegate.willPresentFullScreenViewInvokeCount == 1)
  }

  @Test
  func willDismissFullscreen() {
    let eventDelegate = loadAdAndAssertLoadSuccess()
    let fakeAdView = fakeClient.createdAdViews.first!
    let delegate = fakeAdView.adEventDelegate!

    let fakeAd = makeFakeALAd()
    delegate.ad?(fakeAd, willDismissFullscreenFor: fakeAdView.fakeALAdView)

    #expect(eventDelegate.willDismissFullScreenViewInvokeCount == 1)
  }

  @Test
  func didDismissFullscreen() {
    let eventDelegate = loadAdAndAssertLoadSuccess()
    let fakeAdView = fakeClient.createdAdViews.first!
    let delegate = fakeAdView.adEventDelegate!

    let fakeAd = makeFakeALAd()
    delegate.ad?(fakeAd, didDismissFullscreenFor: fakeAdView.fakeALAdView)

    #expect(eventDelegate.didDismissFullScreenViewInvokeCount == 1)
  }

  @Test
  func unhandledEventsResultInNoCrash() {
    _ = loadAdAndAssertLoadSuccess()
    let fakeAdView = fakeClient.createdAdViews.first!

    let fakeAd = makeFakeALAd()

    // Call wasHiddenIn
    if let displayDelegate = fakeAdView.adDisplayDelegate {
      displayDelegate.ad(fakeAd, wasHiddenIn: fakeAdView.view)
    }

    // Call willLeaveApplicationFor
    if let eventDelegate = fakeAdView.adEventDelegate {
      eventDelegate.ad?(fakeAd, willLeaveApplicationFor: fakeAdView.fakeALAdView)
    }

    // If we reached here without crash, test passes.
    #expect(true)
  }
}
