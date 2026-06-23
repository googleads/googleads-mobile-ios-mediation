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

import AppLovinSDK
import Foundation
import GoogleMobileAds

@objc(GADMAdapterAppLovinUtils)
public class GADMAdapterAppLovinUtils: NSObject {

  private static let alSDKKeyLength = 86
  private static let alZoneIdentifierLength = 16

  // MARK: - Mutable Collection Helpers

  @objc public static func mutableSet(_ set: NSMutableSet?, addObject object: NSObject?) {
    if let set = set, let object = object {
      set.add(object)
    }
  }

  @objc public static func mutableArray(_ array: NSMutableArray?, addObject object: NSObject?) {
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
    _ mapTable: NSMapTable<AnyObject, AnyObject>?,
    setObject value: Any?,
    forKey key: NSCopying?
  ) {
    if let mapTable = mapTable, let value = value, let key = key {
      mapTable.setObject(value as AnyObject, forKey: key as AnyObject)
    }
  }

  @objc public static func mutableArray(_ array: NSMutableArray?, removeObject object: NSObject?) {
    if let array = array, let object = object {
      array.remove(object)
    }
  }

  @objc public static func mutableSet(_ set: NSMutableSet?, removeObject object: NSObject?) {
    if let set = set, let object = object {
      set.remove(object)
    }
  }

  @objc public static func mutableDictionary(
    _ dictionary: NSMutableDictionary?,
    setObject value: Any?,
    forKey key: NSCopying?
  ) {
    if let dictionary = dictionary, let value = value, let key = key {
      dictionary[key] = value
    }
  }

  @objc public static func mutableDictionary(
    _ dictionary: NSMutableDictionary?,
    removeObjectForKey key: NSCopying?
  ) {
    if let dictionary = dictionary, let key = key {
      dictionary.removeObject(forKey: key)
    }
  }

  // MARK: - Error Helpers

  @objc public static func error(
    withCode code: GADMAdapterAppLovinErrorCode,
    description: String
  ) -> NSError {
    return NSError(
      domain: GADMAdapterAppLovinErrorDomain,
      code: code.rawValue,
      userInfo: [NSLocalizedFailureReasonErrorKey: description]
    )
  }

  @objc public static func sdkError(withCode code: Int) -> NSError {
    return NSError(
      domain: GADMAdapterAppLovinSDKErrorDomain,
      code: code,
      userInfo: [NSLocalizedFailureReasonErrorKey: "AppLovin SDK returned a failure callback."]
    )
  }

  @objc public static func childUserError() -> NSError {
    return self.error(
      withCode: .childUser,
      description:
        "GADMobileAds.sharedInstance.requestConfiguration indicates the user is a child. AppLovin SDK 13.0.0 or higher does not support child users."
    )
  }

  @objc public static func isMultipleAdsLoadingEnabled() -> Bool {
    return true
  }

  // MARK: - SDK Key & Zone Helpers

  @objc public static func retrieveSDKKey(fromCredentials credentials: [AnyHashable: Any]?)
    -> String?
  {
    guard let credentials = credentials else { return nil }
    let serverSDKKey = credentials[GADMAdapterAppLovinSDKKey] as? String
    if let serverSDKKey = serverSDKKey, self.isValidAppLovinSDKKey(serverSDKKey) {
      return serverSDKKey
    }
    return nil
  }

  @objc public static func isValidAppLovinSDKKey(_ sdkKey: String) -> Bool {
    return sdkKey.count == alSDKKeyLength
  }

  @objc public static func zoneIdentifier(forConnector connector: MediationAdRequest) -> String? {
    return self.retrieveZoneIdentifier(fromDict: connector.credentials())
  }

  @objc public static func zoneIdentifier(forAdConfiguration adConfig: MediationAdConfiguration)
    -> String?
  {
    return self.retrieveZoneIdentifier(fromDict: adConfig.credentials.settings)
  }

  private static func retrieveZoneIdentifier(fromDict dict: [AnyHashable: Any]?) -> String? {
    guard let dict = dict else { return nil }
    let customZoneIdentifier = dict[GADMAdapterAppLovinZoneIdentifierKey] as? String

    if let customZoneIdentifier = customZoneIdentifier {
      if customZoneIdentifier.count == alZoneIdentifierLength {
        return customZoneIdentifier
      }
      if !customZoneIdentifier.isEmpty {
        // Custom zone is invalid - return nil (adapter will fail the ad load).
        return nil
      }
    }

    // Use default zone if no custom zone attempted (or empty).
    self.log(
      "WARNING: Please provide a custom zone in your AdMob configuration. Using default zone...")
    return GADMAdapterAppLovinDefaultZoneIdentifier
  }

  // MARK: - Banner Size Helpers

  @objc public static func appLovinAdSize(fromRequestedSize size: AdSize) -> ALAdSize? {
    let banner = adSizeFor(cgSize: CGSize(width: 320, height: 50))
    let leaderboard = adSizeFor(cgSize: CGSize(width: 728, height: 90))

    let isIPad = UIDevice.current.userInterfaceIdiom == .pad
    var mutablePotentials = [nsValue(for: banner)]
    if isIPad {
      mutablePotentials.append(nsValue(for: leaderboard))
    }

    let closestSize = closestValidSizeForAdSizes(original: size, possibleAdSizes: mutablePotentials)

    if isAdSizeEqualToSize(size1: closestSize, size2: banner) {
      return ALAdSize.banner
    }
    if isAdSizeEqualToSize(size1: closestSize, size2: leaderboard) {
      return ALAdSize.leader
    }

    self.log("Unable to retrieve AppLovin size from GADAdSize: \(string(for: size))")
    return nil
  }

  // MARK: - Logging

  @objc public static func log(_ message: String) {
    NSLog("AppLovinAdapter: %@", message)
  }

  @objc public static func isChildUser() -> Bool {
    let requestConfiguration = MobileAds.shared.requestConfiguration
    return requestConfiguration.ageRestrictedTreatment == .child
      || requestConfiguration.tagForChildDirectedTreatment?.boolValue == true
      || requestConfiguration.tagForUnderAgeOfConsent?.boolValue == true
  }
}
