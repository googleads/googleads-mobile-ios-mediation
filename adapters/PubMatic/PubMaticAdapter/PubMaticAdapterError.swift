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

import Foundation

public struct PubMaticAdapterError: Error {

  public enum ErrorCode: Int, Sendable {
    /// Server configuration missing a required publisher ID.
    case serverConfigurationMissingPublisherId = 101

    /// The bidding signal collection request failed because multiple formats, no format, or an unsupported
    /// format was specified in the request parameters.
    case invalidRTBRequestParameters = 102

    /// Invalid ad configuration for loading an ad.
    case invalidAdConfiguration = 103

    /// Failed to present an interstitial ad because the ad was not ready.
    case interstitialAdNotReadyForPresentation = 104

    /// Failed to present an interstitial ad because the ad was not ready.
    case rewardedAdNotReadyForPresentation = 105

    /// Failed to load one of the native ad image sources.
    case failedToLoadNativeAdImageSource = 106

    /// Ad configuration missing a required publisher ID.
    case adConfigurationMissingPublisherId = 107

    /// Ad configuration missing a required profile ID.
    case adConfigurationMissingProfileId = 108

    /// Ad configuration contains a non-number profile ID.
    case invalidProfileId = 109

    /// Ad configuration missing an ad unit ID.
    case adConfigurationMissingAdUnitId = 110
  }

  public static let domain = "com.google.ads.mediation.pubmatic"

  /// The error code of this error.
  public let errorCode: ErrorCode

  /// The description of this error.
  public let description: String

  public func toNSError() -> NSError {
    return Util.error(withDomain: Self.domain, code: errorCode.rawValue, description: description)
  }

}
