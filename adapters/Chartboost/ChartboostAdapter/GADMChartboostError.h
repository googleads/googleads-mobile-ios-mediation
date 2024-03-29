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

#if __has_include(<ChartboostSDK/ChartboostSDK.h>)
#import <ChartboostSDK/ChartboostSDK.h>
#else
#import "ChartboostSDK.h"
#endif
#import <Foundation/Foundation.h>

/// Returns an NSError with description acquired from the CHBCacheError.
NSError *GADMChartboostErrorForCHBCacheError(CHBCacheError *error);

/// Returns an NSError with description acquired from the CHBShowError.
NSError *GADMChartboostErrorForCHBShowError(CHBShowError *error);

/// Returns an NSError with description acquired from the CHBClickError.
NSError *GADMChartboostErrorForCHBClickError(CHBClickError *error);
