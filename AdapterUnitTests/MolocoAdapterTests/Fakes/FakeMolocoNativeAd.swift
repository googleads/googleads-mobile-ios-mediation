// Copyright 2024 Google LLC.
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
import GoogleMobileAds
import MolocoSDK

/// A fake implementation of MolocoNativeAd.
final class FakeMolocoNativeAd {

  /// The load error that occured.
  let loadError: Error?

  /// The show error that occured.
  let showError: Error?

  /// Var to capture the bid response that was used to load the ad on Moloco SDK. Used for
  /// assertion. It is initlialized to a value that is never asserted for.
  var bidResponseUsedToLoadMolocoAd: String = "nil"

  // MolocoSDK.MolocoNativeAd properties.
  var nativeDelegate: (any MolocoSDK.MolocoNativeAdDelegate)?
  var isReady: Bool
  var nativeAssets: MolocoNativeAdAssests? = nil

  /// If loadError is nil, this fake mimics load success. If loadError is not nil, this fake mimics
  /// load failure.
  init(
    nativeDelegate: any MolocoSDK.MolocoNativeAdDelegate, loadError: Error?,
    isReadyToBeShown: Bool = true, showError: Error?
  ) {
    self.nativeDelegate = nativeDelegate
    self.isReady = isReadyToBeShown
    self.loadError = loadError
    self.showError = showError
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}

// MARK: - MolocoSDK.MolocoNativeAd

extension FakeMolocoNativeAd: MolocoSDK.MolocoNativeAd {
  var adView: UIView {
    UIView()
  }
  
  var delegate: (any MolocoSDK.MolocoNativeAdDelegate)? {
    get {
      nativeDelegate
    }
    set(newValue) {
      nativeDelegate = newValue
    }
  }
  
  var assets: (any MolocoSDK.MolocoNativeAdAssests)? {
    nativeAssets
  }
  
  var type: MolocoSDK.AdNativeType {
    .unknownType
  }
  
  func handleClick() {
    delegate?.didHandleClick?(ad: self)
  }
  
  func handleImpression() {
    delegate?.didHandleImpression?(ad: self)
  }

  func show(from viewController: UIViewController, muted: Bool) {
    // No-op.
  }

  func load(bidResponse: String) {
    bidResponseUsedToLoadMolocoAd = bidResponse
    guard let loadError else {
      nativeDelegate?.didLoad(ad: self)
      return
    }
    nativeDelegate?.failToLoad(ad: self, with: loadError)
  }

  func destroy() {
    // No-op.
  }

}
