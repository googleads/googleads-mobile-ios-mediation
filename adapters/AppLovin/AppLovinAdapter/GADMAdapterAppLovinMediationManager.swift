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

import Foundation

@objc(GADMAdapterAppLovinMediationManager)
public class GADMAdapterAppLovinMediationManager: NSObject, @unchecked Sendable {

  @objc public static let sharedInstance = GADMAdapterAppLovinMediationManager()

  private let lock = NSLock()
  private var requestedInterstitialZoneIdentifiers = Set<String>()
  private var requestedRewardedZoneIdentifiers = Set<String>()

  private override init() {
    super.init()
  }

  @objc public func containsAndAddInterstitialZoneIdentifier(_ zoneIdentifier: String) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    let containsZone = requestedInterstitialZoneIdentifiers.contains(zoneIdentifier)
    requestedInterstitialZoneIdentifiers.insert(zoneIdentifier)
    return containsZone
  }

  @objc public func removeInterstitialZoneIdentifier(_ zoneIdentifier: String) {
    lock.lock()
    defer { lock.unlock() }
    requestedInterstitialZoneIdentifiers.remove(zoneIdentifier)
  }

  @objc public func removeRewardedZoneIdentifier(_ zoneIdentifier: String) {
    lock.lock()
    defer { lock.unlock() }
    requestedRewardedZoneIdentifiers.remove(zoneIdentifier)
  }

  @objc public func containsAndAddRewardedZoneIdentifier(_ zoneIdentifier: String) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    let containsZone = requestedRewardedZoneIdentifiers.contains(zoneIdentifier)
    requestedRewardedZoneIdentifiers.insert(zoneIdentifier)
    return containsZone
  }
}
