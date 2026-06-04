// Copyright 2026 Google LLC.
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

@objc(GADMAdapterChartboostUtils)
public class GADMAdapterChartboostUtils: NSObject {

  @objc public static func mutableDictionary(
    _ dictionary: NSMutableDictionary,
    setObject value: Any?,
    forKey key: NSCopying?
  ) {
    if let value = value, let key = key {
      dictionary[key] = value
    }
  }

  @objc public static func mutableArray(
    _ array: NSMutableArray?,
    addObject object: NSObject?
  ) {
    if let array = array, let object = object {
      array.add(object)
    }
  }

  @objc public static func mapTable(
    _ mapTable: NSMapTable<AnyObject, AnyObject>?,
    removeObjectForKey key: Any?
  ) {
    if let mapTable = mapTable, let key = key {
      mapTable.removeObject(forKey: key as AnyObject)
    }
  }

  @objc public static func mapTable(
    _ mapTable: NSMapTable<AnyObject, AnyObject>,
    setObject value: Any?,
    forKey key: NSCopying?
  ) {
    if let value = value, let key = key {
      mapTable.setObject(value as AnyObject, forKey: key as AnyObject)
    }
  }

  @objc public static func location(
    fromConnector connector: MediationAdNetworkConnector
  ) -> String {
    return location(from: connector.credentials()?[GADMAdapterChartboostAdLocation] as? String)
  }

  @objc public static func location(
    fromAdConfiguration adConfiguration: MediationAdConfiguration
  ) -> String {
    return location(
      from: adConfiguration.credentials.settings[GADMAdapterChartboostAdLocation] as? String)
  }

  private static func location(from string: String?) -> String {
    guard let string = string else {
      return "Default"
    }
    let adLocation = string.trimmingCharacters(in: .whitespacesAndNewlines)
    if adLocation.isEmpty {
      print("Missing or Invalid Chartboost location. Using Chartboost's default location.")
      return "Default"
    }
    return adLocation
  }

  @objc public static func mediation() -> CHBMediation {
    let version = MobileAds.shared.versionNumber
    let versionString =
      "afma-sdk-i-v\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    return CHBMediation(
      name: "AdMob",
      libraryVersion: versionString,
      adapterVersion: GADMAdapterChartboostVersion
    )
  }

  @objc public static func error(
    withCode code: GADMAdapterChartboostErrorCode,
    description: String
  ) -> NSError {
    let userInfo: [String: Any] = [
      NSLocalizedDescriptionKey: description,
      NSLocalizedFailureReasonErrorKey: description,
    ]
    return NSError(
      domain: GADMAdapterChartboostErrorDomain,
      code: code.rawValue,
      userInfo: userInfo
    )
  }

  @objc public static func bannerSize(
    from adSize: AdSize,
    error: NSErrorPointer
  ) -> CHBBannerSize {
    let potentials = [
      nsValue(for: AdSizeBanner),
      nsValue(for: AdSizeMediumRectangle),
      nsValue(for: AdSizeLeaderboard),
    ]

    let closestSize = closestValidSizeForAdSizes(original: adSize, possibleAdSizes: potentials)
    if isAdSizeEqualToSize(size1: closestSize, size2: AdSizeBanner) {
      return CHBBannerSizeStandard
    } else if isAdSizeEqualToSize(size1: closestSize, size2: AdSizeMediumRectangle) {
      return CHBBannerSizeMedium
    } else if isAdSizeEqualToSize(size1: closestSize, size2: AdSizeLeaderboard) {
      return CHBBannerSizeLeaderboard
    }

    if error != nil {
      let description =
        "Chartboost's supported banner sizes are not valid for the requested ad size. Requested ad size: \(string(for: adSize))"
      error?.pointee = self.error(
        withCode: .bannerSizeMismatch,
        description: description
      )
    }

    return CHBBannerSize()
  }

  @objc public static func setCOPPAUsingRequestConfiguration() {
    let tagForChildDirectedTreatment =
      MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment
    let tagForUnderAgeOfConsent =
      MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent
    let ageRestrictedTreatment =
      MobileAds.shared.requestConfiguration.ageRestrictedTreatment

    if tagForChildDirectedTreatment == true || tagForUnderAgeOfConsent == true
      || ageRestrictedTreatment == .child
    {
      Chartboost.addDataUseConsent(CHBDataUseConsent.COPPA(isChildDirected: true))
    } else if tagForChildDirectedTreatment == false || tagForUnderAgeOfConsent == false {
      Chartboost.addDataUseConsent(CHBDataUseConsent.COPPA(isChildDirected: false))
    }
  }
}
