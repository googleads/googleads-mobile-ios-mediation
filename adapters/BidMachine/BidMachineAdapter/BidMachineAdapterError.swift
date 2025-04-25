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

public final class BidMachineAdapterError: Error {

  public enum ErrorCode: Int, Sendable {
    /// Server configuration missing a required publisher ID.
    case serverConfigurationMissingPublisherId = 101

    /// The bidding signal collection request failed because the RTB parameters do not contains ad format
    /// or specified format is not supported.
    case invalidRTBRequestParameters = 102

    /// Invalid ad configuration for loading an ad.
    case invalidAdConfiguration = 103

    /// Bid Machine SDK returned non-banner ad to the banner ad's BidMachineAdProtocol didLoadAd
    /// delegate method. Should never happen.
    case bidMachineReturnedNonBannerAd = 104

    /// Fullscreen ad is not ready for presentation.
    case adNotReadyForPresentation = 105

    /// Bid Machine SDK returned non-native ad to the native ad's BidMachineAdProtocol didLoadAd
    /// delegate method. Should never happen.
    case bidMachineReturnedNonNativeAd = 106

    /// Failed to load one of the native ad image sources.
    case failedToLoadNativeAdImageSource = 107
  }

  public static let domain = "com.google.mediation.bidmachine"

  /// The error code of this error.
  public let errorCode: ErrorCode

  /// The description of this error.
  public let description: String

  init(errorCode: ErrorCode, description: String) {
    self.errorCode = errorCode
    self.description = description
  }

  public func toNSError() -> NSError {
    return Util.error(withDomain: Self.domain, code: errorCode.rawValue, description: description)
  }

}
