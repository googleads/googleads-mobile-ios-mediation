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

import BidMachine
import GoogleMobileAds
import UIKit

@testable import GoogleBidMachineAdapter

final class FakeNativeAdProxy: NSObject, NativeAdProxy {

  var titleLabel: UILabel?

  var callToActionLabel: UILabel?

  var descriptionLabel: UILabel?

  var iconView: UIImageView?

  var mediaContainerView: UIView?

  var adChoiceView: UIView?

  var headline: String?

  var images: [NativeAdImage]?

  var body: String?

  var icon: NativeAdImage?

  var callToAction: String?

  var starRating: NSDecimalNumber?

  var store: String?

  var price: String?

  var advertiser: String?

  var extraAssets: [String: Any]?

  var shouldDownloadSucceed = true

  func downLoadImageAssets(
    completionHandler: @escaping (GoogleBidMachineAdapter.BidMachineAdapterError?) -> Void
  ) {
    if shouldDownloadSucceed {
      completionHandler(nil)
    } else {
      completionHandler(
        BidMachineAdapterError(
          errorCode: .failedToLoadNativeAdImageSource, description: "Test error"))
    }
  }
}
