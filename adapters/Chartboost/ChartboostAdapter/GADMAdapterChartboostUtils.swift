// Copyright 2019 Google LLC.
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

import ChartboostSDK
import Foundation
import GoogleMobileAds
import UIKit

/// Utility class for the Chartboost adapter.
@objc(GADMAdapterChartboostUtils)
public final class GADMAdapterChartboostUtils: NSObject {

  private override init() {}

  /// Returns true if the system version is greater than or equal to the minimum supported OS version.
  @objc
  @MainActor
  public static var isOSVersionSupported: Bool {
    let minimumOSVersion = GADMAdapterChartboostConstants.minimumOSVersion
    return UIDevice.current.systemVersion.compare(minimumOSVersion, options: .numeric)
      != .orderedAscending
  }

  /// Sets |value| for |key| in |dictionary| if |value| is not nil.
  @objc
  public static func setObject(
    _ dictionary: NSMutableDictionary, key: NSCopying?, value: Any?
  ) {
    if let value, let key {
      dictionary[key] = value
    }
  }

  /// Returns a valid Chartboost ad location string from the given ad configuration.
  @objc
  public static func location(from adConfiguration: MediationAdConfiguration) -> String {
    let adLocation =
      adConfiguration.credentials.settings[GADMAdapterChartboostConstants.adLocation] as? String
    return location(fromString: adLocation)
  }

  /// Returns a valid Chartboost ad location based on the given string.
  @objc
  public static func location(fromString string: String?) -> String {
    guard let string else {
      NSLog("Missing or Invalid Chartboost location. Using Chartboost's default location.")
      return "Default"
    }
    let adLocation = string.trimmingCharacters(in: .whitespacesAndNewlines)
    if adLocation.isEmpty {
      NSLog("Missing or Invalid Chartboost location. Using Chartboost's default location.")
      return "Default"
    }
    return adLocation
  }

  /// Creates and returns a Chartboost mediation object.
  @objc
  public static func mediation() -> CHBMediation {
    let versionNumber = MobileAds.shared.versionNumber
    let versionString =
      "afma-sdk-i-v\(versionNumber.majorVersion).\(versionNumber.minorVersion).\(versionNumber.patchVersion)"
    return CHBMediation(
      name: "AdMob",
      libraryVersion: versionString,
      adapterVersion: GADMAdapterChartboostConstants.adapterVersion)
  }

  /// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
  /// NSLocalizedFailureReasonErrorKey values set to |description|.
  @objc
  public static func error(withCode code: Int, description: String) -> NSError {
    let userInfo = [
      NSLocalizedDescriptionKey: description,
      NSLocalizedFailureReasonErrorKey: description,
    ]
    return NSError(
      domain: GADMAdapterChartboostConstants.errorDomain,
      code: code,
      userInfo: userInfo)
  }

  /// Checks whether the user provided consent to a Google Ad Tech Provider (ATP) in Google’s
  /// Additional Consent technical specification. For more details, see [Google’s Additional
  /// Consent technical specification](https://support.google.com/admob/answer/9681920).
  ///
  /// Returns `GADMAdapterChartboostConsentResultUnknown` if GDPR does not apply or if positive or
  /// negative consent was not explicitly detected.
  ///
  /// Parameters
  /// - `vendorId`: a Google Ad Tech Provider (ATP) ID from [Additional Consent
  /// Providers](https://storage.googleapis.com/tcfac/additional-consent-providers.csv).
  ///
  /// Returns: A `GADMAdapterChartboostConsentResult` indicating consent for the given ATP.
  @objc
  public static func hasACConsent(_ vendorID: Int) -> GADMAdapterChartboostConsentResult {
    let userDefaults = UserDefaults.standard

    let gdprApplies = userDefaults.integer(forKey: "IABTCF_gdprApplies")
    if gdprApplies != 1 {
      return .unknown
    }

    guard let consentString = userDefaults.string(forKey: "IABTCF_AddtlConsent"),
      let additionalConsent = AdditionalConsent(consentString)
    else {
      return .unknown
    }

    return additionalConsent.status(for: vendorID)
  }

  /// Returns the closest CHBBannerSize size from the requested GADAdSize.
  @objc
  public static func bannerSize(fromAdSize gadAdSize: AdSize, error: NSErrorPointer)
    -> CHBBannerSize
  {
    let potentials = [
      nsValue(for: AdSizeBanner),
      nsValue(for: AdSizeMediumRectangle),
      nsValue(for: AdSizeLeaderboard),
    ]

    let closestSize = closestValidSizeForAdSizes(original: gadAdSize, possibleAdSizes: potentials)
    if isAdSizeEqualToSize(size1: closestSize, size2: AdSizeBanner) {
      return CHBBannerSizeStandard
    }
    if isAdSizeEqualToSize(size1: closestSize, size2: AdSizeMediumRectangle) {
      return CHBBannerSizeMedium
    }
    if isAdSizeEqualToSize(size1: closestSize, size2: AdSizeLeaderboard) {
      return CHBBannerSizeLeaderboard
    }

    if let error {
      let description =
        "Chartboost's supported banner sizes are not valid for the requested ad size. "
        + "Requested ad size: \(string(for: gadAdSize))"
      error.pointee = GADMAdapterChartboostUtils.error(
        withCode: GADMAdapterChartboostErrorCode.bannerSizeMismatch.rawValue,
        description: description)
    }

    return CHBBannerSize(width: 0, height: 0)
  }

  /// Set Chartboost COPPA configuration using
  /// GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment.
  @objc
  public static func setCOPPAUsingRequestConfiguration() {
    let requestConfiguration = MobileAds.shared.requestConfiguration
    let tagForChildDirectedTreatment = requestConfiguration.tagForChildDirectedTreatment
    let tagForUnderAgeOfConsent = requestConfiguration.tagForUnderAgeOfConsent
    let ageRestrictedTreatment = requestConfiguration.ageRestrictedTreatment

    if tagForChildDirectedTreatment == true || tagForUnderAgeOfConsent == true
      || ageRestrictedTreatment == .child
    {
      Chartboost.addDataUseConsent(CHBDataUseConsent.COPPA(isChildDirected: true))
    } else if tagForChildDirectedTreatment == false || tagForUnderAgeOfConsent == false {
      Chartboost.addDataUseConsent(CHBDataUseConsent.COPPA(isChildDirected: false))
    }
  }
}

private struct AdditionalConsent {
  let consentString: String
  let version: Int
  let parts: [String]

  init?(_ consentString: String) {
    guard !consentString.isEmpty else { return nil }
    let parts = consentString.components(separatedBy: "~")
    guard let version = Int(parts[0]) else { return nil }
    self.consentString = consentString
    self.version = version
    self.parts = parts
  }

  func status(for vendorID: Int) -> GADMAdapterChartboostConsentResult {
    let vendorIDString = String(vendorID)

    switch version {
    case 1:
      NSLog(
        "The IABTCF_AddtlConsent string uses version 1 of Google’s Additional Consent "
          + "spec. Version 1 does not report vendors to whom the user denied consent. To "
          + "detect vendors that the user denied consent, upgrade to a CMP that supports "
          + "version 2 of Google's Additional Consent technical specification.")

      guard parts.count != 1 else {
        return .unknown
      }

      guard parts.count == 2 else {
        NSLog(
          "Could not parse the IABTCF_AddtlConsent string: \"\(consentString)\". "
            + "String had more parts than expected. "
            + "Did your CMP write IABTCF_AddtlConsent correctly?"
        )
        return .unknown
      }

      let consentedIDs = parts[1].components(separatedBy: ".")
      if consentedIDs.contains(vendorIDString) {
        return .true
      }
      return .unknown

    case 2...:
      guard parts.count >= 3 else {
        NSLog(
          "Could not parse the IABTCF_AddtlConsent string: \"\(consentString)\". "
            + "String has less parts than expected. "
            + "Did your CMP write IABTCF_AddtlConsent correctly?"
        )
        return .unknown
      }

      let disclosedIDs = parts[2].components(separatedBy: ".")
      guard disclosedIDs.first == "dv" else {
        NSLog(
          "Could not parse the IABTCF_AddtlConsent string: \"\(consentString)\". "
            + "Expected disclosed vendors part to have the string \"dv.\". "
            + "Did your CMP write IABTCF_AddtlConsent correctly?"
        )
        return .unknown
      }

      let consentedIDs = parts[1].components(separatedBy: ".")
      if consentedIDs.contains(vendorIDString) {
        return .true
      }

      if disclosedIDs.contains(vendorIDString) {
        return .false
      }

      return .unknown

    default:
      NSLog(
        "Could not parse the IABTCF_AddtlConsent string: \"\(consentString)\". "
          + "Spec version was unexpected. Did your CMP write IABTCF_AddtlConsent correctly?"
      )
      return .unknown
    }
  }
}
