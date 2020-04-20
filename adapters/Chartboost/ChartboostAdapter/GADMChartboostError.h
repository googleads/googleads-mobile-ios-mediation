// Copyright 2016 Google Inc.
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

#import <Chartboost/CHBAdDelegate.h>
#import <Chartboost/Chartboost.h>
#import <Foundation/Foundation.h>

/// Returns an NSError with NSLocalizedDescriptionKey and NSLocalizedFailureReasonErrorKey values
/// set to |description|.
NSError *GADChartboostErrorWithDescription(NSString *description);

/// Returns an NSError with description acquired from the CBLoadError.
NSError *adRequestErrorTypeForCBLoadError(CBLoadError error);

/// Returns an NSError with description acquired from the CHBCacheError.
NSError *NSErrorForCHBCacheError(CHBCacheError *error);

/// Returns an NSError with description acquired from the CHBShowError.
NSError *NSErrorForCHBShowError(CHBShowError *error);

/// Returns an NSError with description acquired from the CHBClickError.
NSError *NSErrorForCHBClickError(CHBClickError *error);
