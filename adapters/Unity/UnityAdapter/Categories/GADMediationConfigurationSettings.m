// Copyright 2021 Google LLC.
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

#import "GADMediationConfigurationSettings.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityUtils.h"

@implementation GADMediationAdConfiguration (Settings)

- (nonnull NSString *)placementId {
  return self.credentials.settings[GADMAdapterUnityPlacementID];
}

- (nonnull NSString *)gameId {
  return self.credentials.settings[GADMAdapterUnityGameID];
}

@end

@implementation GADMediationServerConfiguration (Settings)

- (nonnull NSSet *)gameIds {
  NSMutableSet *gameIDs = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *cred in self.credentials) {
    NSString *gameIDFromSettings = cred.settings[GADMAdapterUnityGameID];
    GADMAdapterUnityMutableSetAddObject(gameIDs, gameIDFromSettings);
  }
  return gameIDs;
}

@end
