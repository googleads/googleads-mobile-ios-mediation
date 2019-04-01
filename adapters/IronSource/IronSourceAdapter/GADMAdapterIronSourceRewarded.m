// Copyright 2019 Google Inc.
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

#import "GADMAdapterIronSourceRewarded.h"
#import "GADMediationAdapterIronSource.h"

@implementation GADMAdapterIronSourceRewarded

/// TODO(Google): Remove this class once Google's server points to GADMediationAdapterIronSource
/// directly to ask for a rewarded ad.

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterIronSource class];
}

@end
