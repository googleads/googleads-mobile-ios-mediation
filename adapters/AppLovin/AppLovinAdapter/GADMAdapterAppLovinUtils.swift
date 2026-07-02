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

  private static let sdkKeyLength = 86
  private static let zoneIdentifierLength = 16

  @objc public static func mutableArrayAddObject(_ array: NSMutableArray?, object: Any?) {
    if let array, let object {
      array.add(object)
    }
  }

  @objc public static func mapTableRemoveObject(
    forKey key: Any?, in mapTable: NSMapTable<AnyObject, AnyObject>?
  ) {
    if let mapTable, let key {
      mapTable.removeObject(forKey: key as AnyObject)
    }
  }

  @objc public static func mapTableSetObject(
    _ mapTable: NSMapTable<AnyObject, AnyObject>, forKey key: NSCopying?, value: Any?
  ) {
    if let key, let value {
      mapTable.setObject(value as AnyObject, forKey: key as AnyObject)
    }
  }

  @objc public static func mutableArrayRemoveObject(_ array: NSMutableArray?, object: Any?) {
    if let array, let object {
      array.remove(object)
    }
  }

  @objc public static func mutableSetRemoveObject(_ set: NSMutableSet?, object: Any?) {
    if let set, let object {
      set.remove(object)
    }
  }

  @objc public static func mutableDictionarySetObject(
    _ dictionary: NSMutableDictionary, forKey key: NSCopying?, value: Any?
  ) {
    if let key, let value {
      dictionary[key] = value
    }
  }

  @objc public static func mutableDictionaryRemoveObject(
    forKey key: NSCopying?, in dictionary: NSMutableDictionary
  ) {
    if let key {
      dictionary.removeObject(forKey: key)
    }
  }

  @objc public static func error(withCode code: GADMAdapterAppLovinErrorCode, description: String)
    -> Error
  {
    return NSError(
      domain: GADMAdapterAppLovinConstant.errorDomain,
      code: code.rawValue,
      userInfo: [NSLocalizedFailureReasonErrorKey: description]
    )
  }

  @objc public static func sdkError(withCode code: Int) -> Error {
    return NSError(
      domain: GADMAdapterAppLovinConstant.sdkErrorDomain,
      code: code,
      userInfo: [NSLocalizedFailureReasonErrorKey: "AppLovin SDK returned a failure callback."]
    )
  }

  @objc public static func childUserError() -> Error {
    return error(
      withCode: .childUser,
      description:
        "GADMobileAds.sharedInstance.requestConfiguration indicates the user is a child. AppLovin SDK 13.0.0 or higher does not support child users."
    )
  }

  /// Always set to true.
  ///
  /// TODO: Remove the code branches for the case where this is false since this is
  /// always true now.
  @objc public static func isMultipleAdsLoadingEnabled() -> Bool {
    return true
  }

  @objc public static func retrieveSDKKey(fromCredentials credentials: [AnyHashable: Any])
    -> String?
  {
    if let serverSDKKey = credentials[GADMAdapterAppLovinConstant.sdkKey] as? String,
      isValidAppLovinSDKKey(serverSDKKey)
    {
      return serverSDKKey
    }
    return nil
  }

  @objc public static func isValidAppLovinSDKKey(_ sdkKey: String) -> Bool {
    return sdkKey.count == Self.sdkKeyLength
  }

  @objc public static func zoneIdentifier(forConnector connector: MediationAdRequest) -> String? {
    return retrieveZoneIdentifier(from: connector.credentials())
  }

  @objc public static func zoneIdentifier(forAdConfiguration adConfig: MediationAdConfiguration)
    -> String?
  {
    return retrieveZoneIdentifier(from: adConfig.credentials.settings)
  }

  private static func retrieveZoneIdentifier(from dict: [AnyHashable: Any]?) -> String? {
    guard let dict = dict else { return GADMAdapterAppLovinConstant.defaultZoneIdentifier }
    let customZoneIdentifier = dict[GADMAdapterAppLovinConstant.zoneIdentifierKey] as? String

    // Custom zone found and is valid.
    if let customZoneIdentifier, customZoneIdentifier.count == Self.zoneIdentifierLength {
      return customZoneIdentifier
    }

    // Use default zone if no custom zone attempted.
    if customZoneIdentifier?.isEmpty ?? true {
      log(
        "WARNING: Please provide a custom zone in your AdMob configuration. Using default zone...")
      return GADMAdapterAppLovinConstant.defaultZoneIdentifier
    }

    // Custom zone is invalid - return nil (adapter will fail the ad load).
    return nil
  }

  @MainActor
  @objc public static func appLovinAdSize(fromRequestedSize size: AdSize) -> ALAdSize? {
    let isIPad = UIDevice.current.userInterfaceIdiom == .pad
    let banner = AdSizeBanner
    let leaderboard = AdSizeLeaderboard
    var potentials = [nsValue(for: banner)]
    if isIPad {
      potentials = [nsValue(for: banner), nsValue(for: leaderboard)]
    }
    let closestSize = closestValidSizeForAdSizes(original: size, possibleAdSizes: potentials)
    if isAdSizeEqualToSize(size1: closestSize, size2: banner) {
      return ALAdSize.banner
    }
    if isAdSizeEqualToSize(size1: closestSize, size2: leaderboard) {
      return ALAdSize.leader
    }
    log("Unable to retrieve AppLovin size from GADAdSize: \(string(for: size))")
    return nil
  }

  @objc public static func log(_ message: String) {
    NSLog("AppLovinAdapter: %@", message)
  }

  @objc public static func isChildUser() -> Bool {
    let requestConfiguration = MobileAds.shared.requestConfiguration
    return requestConfiguration.ageRestrictedTreatment == .child
      || requestConfiguration.tagForChildDirectedTreatment?.boolValue ?? false
      || requestConfiguration.tagForUnderAgeOfConsent?.boolValue ?? false
  }
}
