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
import GoogleMobileAds
import OpenWrapSDK

final class NativeAdLoader: NSObject {

  /// The native ad configuration.
  private let adConfiguration: MediationNativeAdConfiguration

  /// The completion handler that needs to be called upon finishing loading an ad.
  private var nativeAdLoadCompletionHandler: ((MediationNativeAd?, NSError?) -> Void)?

  /// The queue for processing an ad load completion.
  private let adLoadCompletionQueue: DispatchQueue

  /// The ad load completion handler the must be run after ad load completion.
  private var adLoadCompletionHandler: GADMediationNativeLoadCompletionHandler?

  /// OpenWrapSDKClient used to manage a native ad.
  private let client: OpenWrapSDKClient

  private var nativeAdProxy: NativeAdProxy?

  init(
    adConfiguration: MediationNativeAdConfiguration,
    loadCompletionHandler: @escaping GADMediationNativeLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.adLoadCompletionQueue = DispatchQueue(
      label: "com.google.mediationNativeAdLoadCompletionQueue")
    self.client = OpenWrapSDKClientFactory.createClient()
    super.init()
  }

  func loadAd() {
    if adConfiguration.bidResponse != nil {
      loadRTBAd()
    } else {
      loadWaterfallAd()
    }
  }

  private func loadRTBAd() {
    guard let bidResponse = adConfiguration.bidResponse, let watermark = adConfiguration.watermark
    else {
      handleLoadedAd(
        nil,
        error: PubMaticAdapterError(
          errorCode: .invalidAdConfiguration,
          description: "The ad configuration is invalid."
        ).toNSError())
      return
    }
    client.loadRtbNativeAd(
      bidResponse: bidResponse, testMode: Util.testMode(from: adConfiguration), delegate: self,
      watermarkData: watermark)
  }

  private func loadWaterfallAd() {
    do {
      let publisherId = try Util.publisherId(from: adConfiguration)
      let profileId = try Util.profileId(from: adConfiguration)
      let adUnitId = try Util.adUnitId(from: adConfiguration)
      client.loadWaterfallNativeAd(
        publisherId: publisherId, profileId: profileId, adUnitId: adUnitId,
        testMode: Util.testMode(from: adConfiguration), delegate: self)
    } catch {
      handleLoadedAd(nil, error: error.toNSError())
    }
  }

  private func handleLoadedAd(_ ad: MediationNativeAd?, error: Error?) {
    adLoadCompletionQueue.sync {
      guard let adLoadCompletionHandler else { return }
      let eventDelegate = adLoadCompletionHandler(ad, error)
      nativeAdProxy?.eventDelegate = eventDelegate
      self.adLoadCompletionHandler = nil
    }
  }

}

// MARK: - POBNativeAdLoaderDelegate
extension NativeAdLoader: @preconcurrency POBNativeAdLoaderDelegate {

  @MainActor
  func viewControllerForPresentingModal() -> UIViewController {
    return nativeAdProxy?.viewController ?? Util.rootViewController()
  }

  func nativeAdLoader(
    _ adLoader: POBNativeAdLoader,
    didReceive nativeAd: any POBNativeAd
  ) {
    // POBNativeAd's image assets come in string URLs. The adapter needs to
    // download them before notifying Google Mobile Ads SDK.
    nativeAdProxy = NativeAdProxyFactory.createProxy(with: nativeAd)
    nativeAdProxy?.downLoadImageAssets(completionHandler: { [weak self] error in
      guard let self else { return }

      guard error == nil else {
        self.handleLoadedAd(nil, error: error!.toNSError())
        return
      }

      self.handleLoadedAd(self.nativeAdProxy, error: nil)
    })
  }

  func nativeAdLoader(
    _ adLoader: POBNativeAdLoader,
    didFailToReceiveAdWithError error: any Error
  ) {
    handleLoadedAd(nil, error: error as NSError)
  }

}
