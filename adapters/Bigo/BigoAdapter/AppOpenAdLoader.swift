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

final class AppOpenAdLoader: NSObject {

  /// The app open ad configuration.
  private let adConfiguration: GADMediationAppOpenAdConfiguration

  /// The ad event delegate which is used to report app open related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: MediationAppOpenAdEventDelegate?

  /// The completion handler that needs to be called upon finishing loading an ad.
  private var appOpenAdLoadCompletionHandler: ((MediationAppOpenAd?, NSError?) -> Void)?

  init(
    adConfiguration: GADMediationAppOpenAdConfiguration,
    loadCompletionHandler: @escaping GADMediationAppOpenLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    super.init()

    // Ensure completion handler gets called only once at any situation.
    let adLoadcompletionQueue = DispatchQueue(
      label: "com.google.mediationAppOpenAdLoadCompletionQueue")
    var originaLoadCompletionHandler: GADMediationAppOpenLoadCompletionHandler? =
      loadCompletionHandler
    appOpenAdLoadCompletionHandler = { [weak self] ad, error in
      adLoadcompletionQueue.sync {
        guard let self, originaLoadCompletionHandler != nil else { return }
        self.eventDelegate = originaLoadCompletionHandler?(ad, error)
        originaLoadCompletionHandler = nil
      }
    }
  }

  func loadAd() {
    // TODO: implement and make sure to call |appOpenAdLoadCompletionHandler| after loading an ad.
  }

}

// MARK: - GADMediationAppOpenAd

extension AppOpenAdLoader: MediationAppOpenAd {

  func present(from viewController: UIViewController) {
    eventDelegate?.willPresentFullScreenView()
    // TODO: implement
  }

}

// MARK: - <Other protocols>
// TODO: extend and implement any other protocol, if any.
