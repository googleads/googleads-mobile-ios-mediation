// Copyright 2025 Google LLC.
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
import GoogleMobileAds
import Testing

@testable import AdSurgeAdapter

@MainActor
@Suite("AdSurge adapter utils tests", .serialized)
final class AUTAdSurgeUtilsTests {

  init() {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = nil
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = nil
    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .unspecified
  }

  deinit {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = nil
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = nil
    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .unspecified
  }

  @Test("Application ID returns successfully when single ID is present")
  func applicationId_returnsApplicationId_whenSingleIdPresent() throws {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_app_123"]
    let config = AUTKMediationServerConfiguration()
    config.credentials = [credentials]

    let appId = try Util.applicationID(from: config)
    #expect(appId == "test_app_123")
  }

  @Test("Application ID returns successfully when multiple IDs are present")
  func applicationId_returnsApplicationId_whenMultipleIdsPresent() throws {
    let cred1 = AUTKMediationCredentials()
    cred1.settings = ["application_id": "test_app_1"]
    let cred2 = AUTKMediationCredentials()
    cred2.settings = ["application_id": "test_app_2"]
    let config = AUTKMediationServerConfiguration()
    config.credentials = [cred1, cred2]

    let appId = try Util.applicationID(from: config)
    #expect(appId == "test_app_1" || appId == "test_app_2")
  }

  @Test("Application ID throws error when application ID is missing")
  func applicationId_throwsError_whenApplicationIdMissing() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [:]
    let config = AUTKMediationServerConfiguration()
    config.credentials = [credentials]

    do {
      _ = try Util.applicationID(from: config)
      Issue.record("Expected applicationID to throw error")
    } catch {
      #expect(error.errorCode == .serverConfigurationMissingApplicationId)
    }
  }

  @Test("Ad unit ID returns successfully when present")
  func adUnitId_returnsAdUnitId_whenPresent() throws {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["ad_unit_id": "test_unit_456"]
    let config = AUTKMediationBannerAdConfiguration()
    config.credentials = credentials

    let adUnitId = try Util.adUnitID(from: config)
    #expect(adUnitId == "test_unit_456")
  }

  @Test("Ad unit ID throws error when missing")
  func adUnitId_throwsError_whenMissing() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [:]
    let config = AUTKMediationBannerAdConfiguration()
    config.credentials = credentials

    do {
      _ = try Util.adUnitID(from: config)
      Issue.record("Expected adUnitID to throw error")
    } catch {
      #expect(error.errorCode == .invalidAdConfiguration)
    }
  }

  @Test("Bid response returns successfully when present")
  func bidResponse_returnsBidResponse_whenPresent() throws {
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "test_bid_response"

    let bidResponse = try Util.bidResponse(from: config)
    #expect(bidResponse == "test_bid_response")
  }

  @Test("Bid response throws error when missing")
  func bidResponse_throwsError_whenMissing() {
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = nil

    do {
      _ = try Util.bidResponse(from: config)
      Issue.record("Expected bidResponse to throw error")
    } catch {
      #expect(error.errorCode == .invalidAdConfiguration)
    }
  }

  @Test("Banner size resolves standard banner")
  func bannerSize_resolvesStandardBanner() throws {
    let size = try Util.bannerSize(for: AdSizeBanner)
    #expect(size.width == 320)
    #expect(size.height == 50)
  }

  @Test("Banner size resolves medium rectangle")
  func bannerSize_resolvesMediumRectangle() throws {
    let size = try Util.bannerSize(for: AdSizeMediumRectangle)
    #expect(size.width == 300)
    #expect(size.height == 250)
  }

  @Test("Banner size resolves adaptive banner")
  func bannerSize_resolvesAdaptiveBanner() throws {
    let adaptiveSize = currentOrientationAnchoredAdaptiveBanner(width: 320)
    let size = try Util.bannerSize(for: adaptiveSize)
    #expect(size.width == 320)
    #expect(size.height == 50)
  }

  @Test("Banner size throws error for unsupported size")
  func bannerSize_throwsError_forUnsupportedSize() {
    let unsupportedSize = adSizeFor(cgSize: CGSize(width: 120, height: 600))
    do {
      _ = try Util.bannerSize(for: unsupportedSize)
      Issue.record("Expected bannerSize to throw error")
    } catch {
      #expect(error.errorCode == .unsupportedBannerSize)
    }
  }

  @Test("isAgeRestrictedUser returns 1 when tagForChildDirectedTreatment is true")
  func isAgeRestrictedUser_returnsOne_whenTagForChildDirectedTreatmentTrue() {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true
    #expect(Util.isAgeRestrictedUser() == 1)
  }

  @Test("isAgeRestrictedUser returns 1 when tagForUnderAgeOfConsent is true")
  func isAgeRestrictedUser_returnsOne_whenTagForUnderAgeOfConsentTrue() {
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true
    #expect(Util.isAgeRestrictedUser() == 1)
  }

  @Test("isAgeRestrictedUser returns 1 when ageRestrictedTreatment is child")
  func isAgeRestrictedUser_returnsOne_whenAgeRestrictedTreatmentChild() {
    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .child
    #expect(Util.isAgeRestrictedUser() == 1)
  }

  @Test("isAgeRestrictedUser returns nil when ageRestrictedTreatment is teen")
  func isAgeRestrictedUser_returnsNil_whenAgeRestrictedTreatmentTeen() {
    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .teen
    #expect(Util.isAgeRestrictedUser() == nil)
  }

  @Test("isAgeRestrictedUser returns 0 when tags are false")
  func isAgeRestrictedUser_returnsZero_whenTagsFalse() {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = false
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = false
    #expect(Util.isAgeRestrictedUser() == 0)
  }

  @Test("isAgeRestrictedUser returns nil when unspecified")
  func isAgeRestrictedUser_returnsNil_whenUnspecified() {
    #expect(Util.isAgeRestrictedUser() == nil)
  }

}
