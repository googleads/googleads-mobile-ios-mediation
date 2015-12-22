//
// Copyright (C) 2015 Google, Inc.
//
// SampleMediatedNativeContentAd.h
// Sample Ad Network Custom Event
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

@import Foundation;

#import "../SDK/SampleNativeContentAd.h"

/// This class is responsible for "mapping" a native content ad to the interface
/// expected by the Google Mobile Ads SDK. The names and data types of assets provided
/// by a mediated network don't always line up with the ones expected by the Google
/// Mobile Ads SDK (one might have "title" while the other expects "headline," for
/// example). It's the job of this "mapper" class to smooth out those wrinkles.
@interface SampleMediatedNativeContentAd : NSObject<GADMediatedNativeContentAd>

- (instancetype)initWithSampleNativeContentAd:(nonnull SampleNativeContentAd *)sampleNativeContentAd
    NS_DESIGNATED_INITIALIZER;

@end
