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

@MainActor
@objc(GADMAdapterAppLovinInitializer)
public class GADMAdapterAppLovinInitializer: NSObject {

  @objc public static func initialize(
    withSDKKey sdkKey: String, completionHandler: @escaping @Sendable @MainActor () -> Void
  ) {
    if ALSdk.shared().isInitialized {
      completionHandler()
      return
    }

    let config = ALSdkInitializationConfiguration(sdkKey: sdkKey) { builder in
      builder.mediationProvider = ALMediationProviderAdMob
      builder.pluginVersion = GADMAdapterAppLovinAdapterVersion
    }

    ALSdk.shared().initialize(with: config) { configuration in
      // TODO(b/529681616): Migrate this initializer to async/await.
      DispatchQueue.main.async {
        GADMAdapterAppLovinUtils.log("Finished initializing ALSDK.")
        completionHandler()
      }
    }
  }
}
