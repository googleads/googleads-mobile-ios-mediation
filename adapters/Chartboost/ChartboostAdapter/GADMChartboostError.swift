// Copyright 2016 Google Inc.
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

/// Helper class to create NSError objects from Chartboost SDK errors.
@objc(GADMChartboostError)
public final class GADMChartboostError: NSObject {

  private override init() {}

  /// Returns an NSError with description acquired from the CHBCacheError.
  @objc
  public static func error(forCacheError error: CacheError) -> NSError {
    let suffix =
      if let code = CacheErrorCode(rawValue: error.code) {
        switch code {
        case .internalError:
          "CHBCacheErrorCodeInternalError"
        case .internetUnavailable:
          "CHBCacheErrorCodeInternetUnavailable"
        case .networkFailure:
          "CHBCacheErrorCodeNetworkFailure"
        case .noAdFound:
          "CHBCacheErrorCodeNoAdFound"
        case .sessionNotStarted:
          "CHBCacheErrorCodeSessionNotStarted"
        case .assetDownloadFailure:
          "CHBCacheErrorCodeAssetDownloadFailure"
        case .publisherDisabled:
          "CHBCacheErrorCodePublisherDisabled"
        case .serverError:
          "CHBCacheErrorCodeServerError"
        @unknown default:
          "code \(error.code)"
        }
      } else {
        "code \(error.code)"
      }

    let description = "Chartboost SDK returned a cache error: \(suffix)"
    return GADMAdapterChartboostUtils.error(withCode: 200 + error.code, description: description)
  }

  /// Returns an NSError with description acquired from the CHBShowError.
  @objc
  public static func error(forShowError error: ShowError) -> NSError {
    let suffix =
      if let code = ShowErrorCode(rawValue: error.code) {
        switch code {
        case .internalError:
          "CHBShowErrorCodeInternalError"
        case .sessionNotStarted:
          "CHBShowErrorCodeSessionNotStarted"
        case .internetUnavailable:
          "CHBShowErrorCodeInternetUnavailable"
        case .presentationFailure:
          "CHBShowErrorCodePresentationFailure"
        case .noCachedAd:
          "CHBShowErrorCodeNoCachedAd"
        case .noViewController:
          "CHBShowErrorCodeNoViewController"
        @unknown default:
          "code \(error.code)"
        }
      } else {
        "code \(error.code)"
      }

    let description = "Chartboost SDK returned a show error: \(suffix)"
    return GADMAdapterChartboostUtils.error(withCode: 300 + error.code, description: description)
  }

  /// Returns an NSError with description acquired from the CHBClickError.
  @objc
  public static func error(forClickError error: ClickError) -> NSError {
    let suffix =
      if let code = ClickErrorCode(rawValue: error.code) {
        switch code {
        case .uriInvalid:
          "CHBClickErrorCodeUriInvalid"
        case .uriUnrecognized:
          "CHBClickErrorCodeUriUnrecognized"
        case .internalError:
          "CHBClickErrorCodeInternalError"
        @unknown default:
          "code \(error.code)"
        }
      } else {
        "code \(error.code)"
      }

    let description = "Chartboost SDK returned a click error: \(suffix)"
    return GADMAdapterChartboostUtils.error(withCode: 400 + error.code, description: description)
  }
}
