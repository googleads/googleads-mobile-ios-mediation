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

#import "GADMAdapterIronSourceUtils.h"
#import "GADMAdapterIronSourceConstants.h"

void GADMAdapterIronSourceMutableSetAddObject(NSMutableSet *_Nullable set,
                                              NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

void GADMAdapterIronSourceMapTableSetObjectForKey(NSMapTable *_Nullable mapTable,
                                                  id<NSCopying> _Nullable key, id _Nullable value) {
  if (value && key) {
    [mapTable setObject:value forKey:key];  // Allow pattern.
  }
}

NSError *_Nonnull GADMAdapterIronSourceErrorWithCodeAndDescription(
    GADMAdapterIronSourceErrorCode code, NSString *_Nonnull description) {
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMAdapterIronSourceErrorDomain
                                       code:code
                                   userInfo:userInfo];
  return error;
}

@implementation GADMAdapterIronSourceUtils

#pragma mark Utils Methods

+ (BOOL)isEmpty:(nullable id)value {
  return value == nil || [value isKindOfClass:[NSNull class]] ||
         ([value respondsToSelector:@selector(length)] && [(NSString *)value length] == 0) ||
         ([value respondsToSelector:@selector(length)] && [(NSData *)value length] == 0) ||
         ([value respondsToSelector:@selector(count)] && [(NSArray *)value count] == 0);
}

+ (void)onLog:(nonnull NSString *)log {
  NSLog(@"IronSourceAdapter: %@", log);
}

+ (nonnull NSString *)getAdMobSDKVersion {
  NSString *version = @"";
  NSString *sdkVersion = GADMobileAds.sharedInstance.sdkVersion;
  @try {
    NSUInteger versionIndex = [sdkVersion rangeOfString:@"-v"].location + 1;
    version = [sdkVersion substringFromIndex:versionIndex];
    version = [version stringByReplacingOccurrencesOfString:@"." withString:@""];

  } @catch (NSException *exception) {
    NSLog(@"Unable to parse AdMob SDK version.");
    version = @"";
  }
  return version;
}

@end
