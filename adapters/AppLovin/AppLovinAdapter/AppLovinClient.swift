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
import UIKit

@MainActor
public protocol AppLovinAdView: AnyObject {
  nonisolated var view: UIView { get }
  func render(_ ad: ALAd)
  var adLoadDelegate: (any ALAdLoadDelegate)? { get set }
  var adDisplayDelegate: (any ALAdDisplayDelegate)? { get set }
  var adEventDelegate: (any ALAdViewEventDelegate)? { get set }
  var frame: CGRect { get set }
}

extension ALAdView: AppLovinAdView {
  nonisolated public var view: UIView {
    return self
  }
}

@MainActor
public protocol AppLovinClient: AnyObject {
  var isSDKInitialized: Bool { get }
  func createAdView(size: ALAdSize) -> any AppLovinAdView
  func loadNextAd(
    size: ALAdSize,
    zoneIdentifier: String?,
    andNotify delegate: any ALAdLoadDelegate
  )
  func initialize(
    withSDKKey sdkKey: String,
    completionHandler: @escaping @Sendable @MainActor () -> Void
  )
}

@MainActor
public final class AppLovinClientImpl: AppLovinClient {
  public init() {}

  public var isSDKInitialized: Bool {
    return ALSdk.shared().isInitialized
  }

  public func createAdView(size: ALAdSize) -> any AppLovinAdView {
    return ALAdView(sdk: ALSdk.shared(), size: size)
  }

  public func loadNextAd(
    size: ALAdSize,
    zoneIdentifier: String?,
    andNotify delegate: any ALAdLoadDelegate
  ) {
    let sdk = ALSdk.shared()
    if let zoneIdentifier, !zoneIdentifier.isEmpty {
      sdk.adService.loadNextAd(forZoneIdentifier: zoneIdentifier, andNotify: delegate)
    } else {
      sdk.adService.loadNextAd(size, andNotify: delegate)
    }
  }

  public func initialize(
    withSDKKey sdkKey: String,
    completionHandler: @escaping @Sendable @MainActor () -> Void
  ) {
    if ALSdk.shared().isInitialized {
      completionHandler()
      return
    }

    let config = ALSdkInitializationConfiguration(sdkKey: sdkKey) { builder in
      builder.mediationProvider = ALMediationProviderAdMob
      builder.pluginVersion = GADMAdapterAppLovinConstant.adapterVersion
    }

    ALSdk.shared().initialize(with: config) { configuration in
      DispatchQueue.main.async {
        MainActor.assumeIsolated {
          GADMAdapterAppLovinUtils.log("Finished initializing ALSDK.")
          completionHandler()
        }
      }
    }
  }
}

@MainActor
public final class AppLovinClientFactory {
  #if DEBUG
    nonisolated(unsafe) public static var debugClient: (any AppLovinClient)?
  #endif

  public static func createClient() -> any AppLovinClient {
    #if DEBUG
      if let debugClient = debugClient {
        return debugClient
      }
    #endif
    return AppLovinClientImpl()
  }
}
