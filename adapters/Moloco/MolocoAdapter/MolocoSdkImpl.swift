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

import MolocoSDK
import UIKit

/// Implementation of protocols that calls corresponding Moloco SDK methods.
class MolocoSdkImpl: MolocoInitializer {

  @available(iOS 13.0, *)
  func initialize(
    initParams: MolocoInitParams, completion: ((Bool, Error?) -> Void)?
  ) {
    Moloco.shared.initialize(params: initParams, completion: completion)
  }

  func isInitialized() -> Bool {
    return Moloco.shared.isInitialized
  }
}

// MARK: - MolocoInterstitialFactory

extension MolocoSdkImpl: MolocoInterstitialFactory {

  @available(iOS 13.0, *)
  func createInterstitial(
    for adUnit: String, delegate: MolocoInterstitialDelegate, watermarkData: Data?
  )
    -> MolocoInterstitial?
  {
    Moloco.shared.createInterstitial(
      params: MolocoCreateAdParams(
        adUnit: adUnit, mediation: MolocoConstants.mediationName, watermarkData: watermarkData))
  }

}

// MARK: - MolocoRewardedFactory

extension MolocoSdkImpl: MolocoRewardedFactory {

  @MainActor
  @available(iOS 13.0, *)
  func createRewarded(for adUnit: String, delegate: MolocoRewardedDelegate, watermarkData: Data?)
    -> MolocoRewardedInterstitial?
  {
    Moloco.shared.createRewarded(
      params: MolocoCreateAdParams(
        adUnit: adUnit, mediation: MolocoConstants.mediationName, watermarkData: watermarkData))
  }

}

// MARK: - MolocoBannerFactory

extension MolocoSdkImpl: MolocoBannerFactory {

  @MainActor
  @available(iOS 13.0, *)
  func createBanner(for adUnit: String, delegate: MolocoBannerDelegate, watermarkData: Data?) -> (
    UIView & MolocoAd
  )? {
    guard let rootViewController = MolocoUtils.keyWindow()?.rootViewController else {
      return nil
    }
    return Moloco.shared.createBanner(
      params: MolocoCreateAdParams(
        adUnit: adUnit, mediation: MolocoConstants.mediationName, watermarkData: watermarkData),
      viewController: rootViewController)
  }

  @MainActor
  @available(iOS 13.0, *)
  func createMREC(for adUnit: String, delegate: MolocoBannerDelegate, watermarkData: Data?) -> (
    UIView & MolocoAd
  )? {
    guard let rootViewController = MolocoUtils.keyWindow()?.rootViewController else {
      return nil
    }
    return Moloco.shared.createMREC(
      params: MolocoCreateAdParams(
        adUnit: adUnit, mediation: MolocoConstants.mediationName, watermarkData: watermarkData),
      viewController: rootViewController)
  }

}

extension MolocoSdkImpl: MolocoNativeFactory {

  @MainActor
  @available(iOS 13.0, *)
  func createNativeAd(for adUnit: String, delegate: MolocoNativeAdDelegate, watermarkData: Data?)
    -> MolocoNativeAd?
  {
    guard MolocoUtils.keyWindow()?.rootViewController != nil else {
      return nil
    }
    return Moloco.shared.createNativeAd(
      params: MolocoCreateAdParams(
        adUnit: adUnit, mediation: MolocoConstants.mediationName, watermarkData: watermarkData))
  }

}
// MARK: - MolocoBidTokenGetter

extension MolocoSdkImpl: MolocoBidTokenGetter {

  func getBidToken(completion: @escaping (String?, (any Error)?) -> Void) {
    Moloco.shared.getBidToken(
      params: MolocoParams(mediation: MolocoConstants.mediationName), completion: completion)
  }
}

// MARK: - MolocoSdkVersionProviding

extension MolocoSdkImpl: MolocoSdkVersionProviding {
  func sdkVersion() -> String {
    // Moloco.shared.sdkVersion needs to be accessed from the main thread.
    if Thread.isMainThread {
      return Moloco.shared.sdkVersion
    }

    // DispatchQueue.main.sync cannot be used because it can cause deadlock if
    // Moloco.shared.sdkVersion is accessed elsewhere. Use semaphore as a work
    // around.
    let semaphore = DispatchSemaphore(value: 0)
    var sdkVersion = ""
    DispatchQueue.main.async {
      sdkVersion = Moloco.shared.sdkVersion
      semaphore.signal()
    }

    semaphore.wait()
    return sdkVersion
  }
}

// MARK: - MolocoAgeRestrictedSetter

extension MolocoSdkImpl: MolocoAgeRestrictedSetter {
  func setIsAgeRestrictedUser(isAgeRestrictedUser: Bool) {
    MolocoPrivacySettings.isAgeRestrictedUser = isAgeRestrictedUser
  }
}
