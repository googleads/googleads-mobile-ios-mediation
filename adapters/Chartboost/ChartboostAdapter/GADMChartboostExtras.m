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

#import "GADMChartboostExtras.h"

@implementation GADMChartboostExtras {
  /// Chartboost custom framework.
  CBFramework _framework;
  /// Chartboost custom framework version.
  NSString *_frameworkVersion;
}

+ (nonnull GADMChartboostExtras *)extrasWithFramework:(CBFramework)framework
                                              version:(nullable NSString *)frameworkVersion {
  GADMChartboostExtras *extras = [[GADMChartboostExtras alloc] init];
  extras->_framework = framework;
  extras->_frameworkVersion = [frameworkVersion copy];
  return extras;
}

- (CBFramework)framework {
  return _framework;
}

- (NSString *)frameworkVersion {
  return _frameworkVersion;
}

@end
