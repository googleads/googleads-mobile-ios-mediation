// Copyright 2019 Google LLC.
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

#import "GADMVerizonPrivacy.h"

@implementation GADMVerizonPrivacy

+ (nonnull GADMVerizonPrivacy *)sharedInstance {
  static GADMVerizonPrivacy *sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[GADMVerizonPrivacy alloc] init];
  });
  return sharedInstance;
}

- (void)setDataPrivacy:(VASDataPrivacy *)dataPrivacy {
  _dataPrivacy = dataPrivacy;
  [self updatePrivacyData];
}

- (void)updatePrivacyData {
  if ([VASAds.sharedInstance isInitialized]) {
    [VASAds sharedInstance].dataPrivacy = _dataPrivacy;
  }
}

@end
