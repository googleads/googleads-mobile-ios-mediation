// Copyright 2019 Google LLC
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

#import "VungleRouterConfiguration.h"

#import <VungleSDK/VungleSDK.h>

#import "GADMAdapterVungleUtils.h"

// These keys are also defined in VNGPersisteceManager.
static NSString *const kAdapterMinimumFileSystemSizeForInit = @"vungleMinimumFileSystemSizeForInit";
static NSString *const kAdapterMinimumFileSystemSizeForAdRequest =
    @"vungleMinimumFileSystemSizeForAdRequest";
static NSString *const kAdapterMinimumFileSystemSizeForAssetDownload =
    @"vungleMinimumFileSystemSizeForAssetDownload";

@implementation VungleRouterConfiguration

+ (void)setPublishIDFV:(BOOL)publish {
  [VungleSDK setPublishIDFV:publish];
}

+ (void)setMinSpaceForInit:(int)size {
  if (size >= 0) {
    [[NSUserDefaults standardUserDefaults] setInteger:size
                                               forKey:kAdapterMinimumFileSystemSizeForInit];
  } else {
    GADMAdapterVungleUserDefaultsRemoveObjectForKey(NSUserDefaults.standardUserDefaults,
                                                    kAdapterMinimumFileSystemSizeForInit);
  }
  [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)setMinSpaceForAdLoad:(int)size {
  if (size >= 0) {
    [[NSUserDefaults standardUserDefaults] setInteger:size
                                               forKey:kAdapterMinimumFileSystemSizeForAdRequest];
    [[NSUserDefaults standardUserDefaults]
        setInteger:size
            forKey:kAdapterMinimumFileSystemSizeForAssetDownload];
  } else {
    GADMAdapterVungleUserDefaultsRemoveObjectForKey(NSUserDefaults.standardUserDefaults,
                                                    kAdapterMinimumFileSystemSizeForAdRequest);
    GADMAdapterVungleUserDefaultsRemoveObjectForKey(NSUserDefaults.standardUserDefaults,
                                                    kAdapterMinimumFileSystemSizeForAssetDownload);
  }
  [[NSUserDefaults standardUserDefaults] synchronize];
}
@end
