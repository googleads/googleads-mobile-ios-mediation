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

import OpenWrapSDK
import UIKit

@testable import PubMaticAdapter

final class FakeNativeAd: NSObject, POBNativeAd {

  weak var delegate: POBNativeAdDelegate!
  var registeredInteractionView: UIView?
  var registeredClickableViews: [UIView]?

  func setAdDelegate(_ delegate: any POBNativeAdDelegate) {
    self.delegate = delegate
  }

  func adView() -> POBNativeAdView {
    return POBNativeAdView()
  }

  func adInfoIconView() -> UIImageView? {
    return UIImageView()
  }

  func titleAsset() -> POBNativeAdTitleResponseAsset {
    class FakePOBNativeAdTitleResponseAsset: POBNativeAdTitleResponseAsset {
      override var text: String { "title" }
    }
    return FakePOBNativeAdTitleResponseAsset()
  }

  func descriptionAsset() -> POBNativeAdDataResponseAsset {
    class FakePOBNativeAdDataResponseAsset: POBNativeAdDataResponseAsset {
      override var value: String { "description" }
    }
    return FakePOBNativeAdDataResponseAsset()
  }

  func ratingAsset() -> POBNativeAdDataResponseAsset {
    class FakePOBNativeAdDataResponseAsset: POBNativeAdDataResponseAsset {
      override var value: String { "123" }
    }
    return FakePOBNativeAdDataResponseAsset()
  }

  func priceAsset() -> POBNativeAdDataResponseAsset {
    class FakePOBNativeAdDataResponseAsset: POBNativeAdDataResponseAsset {
      override var value: String { "price" }
    }
    return FakePOBNativeAdDataResponseAsset()
  }

  func advertiserAsset() -> POBNativeAdDataResponseAsset {
    class FakePOBNativeAdDataResponseAsset: POBNativeAdDataResponseAsset {
      override var value: String { "advertiser" }
    }
    return FakePOBNativeAdDataResponseAsset()
  }

  func callToActionAsset() -> POBNativeAdDataResponseAsset {
    class FakePOBNativeAdDataResponseAsset: POBNativeAdDataResponseAsset {
      override var value: String { "cta" }
    }
    return FakePOBNativeAdDataResponseAsset()
  }

  func iconAsset() -> POBNativeAdImageResponseAsset {
    return POBNativeAdImageResponseAsset()
  }

  func mainImageAsset() -> POBNativeAdImageResponseAsset {
    return POBNativeAdImageResponseAsset()
  }

  func titleAsset(withId identifier: Int) -> POBNativeAdTitleResponseAsset {
    return titleAsset()
  }

  func dataAsset(withId identifier: Int) -> POBNativeAdDataResponseAsset {
    class FakePOBNativeAdDataResponseAsset: POBNativeAdDataResponseAsset {
      override var value: String { "data" }
    }
    return FakePOBNativeAdDataResponseAsset()
  }

  func imageAsset(withId identifier: Int) -> POBNativeAdImageResponseAsset {
    return POBNativeAdImageResponseAsset()
  }

  func renderAd(completion: @escaping POBNativeAdRenderingCompletionBlock) {
  }

  func renderAd(
    with templateview: POBNativeTemplateView,
    andCompletion completion: @escaping POBNativeAdRenderingCompletionBlock
  ) {
  }

  func registerView(forInteractions adView: UIView, clickableViews: [UIView]) {
    registeredInteractionView = adView
    registeredClickableViews = clickableViews
  }

}
