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

@implementation GADMAdapterIronSourceUtils

#pragma mark Utils Methods

+ (BOOL)isEmpty:(id)value {
  return value == nil || [value isKindOfClass:[NSNull class]] ||
         ([value respondsToSelector:@selector(length)] && [(NSString *)value length] == 0) ||
         ([value respondsToSelector:@selector(length)] && [(NSData *)value length] == 0) ||
         ([value respondsToSelector:@selector(count)] && [(NSArray *)value count] == 0);
}

+ (NSError *)createErrorWith:(NSString *)description
                   andReason:(NSString *)reason
               andSuggestion:(NSString *)suggestion {
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey : NSLocalizedString(description, nil),
    NSLocalizedFailureReasonErrorKey : NSLocalizedString(reason, nil),
    NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(suggestion, nil)
  };

  return [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:userInfo];
}

+ (void)onLog:(NSString *)log {
  NSLog(@"IronSourceAdapter: %@", log);
}

+ (NSString *)getAdMobSDKVersion {
  NSString *version = @"";
  NSString *sdkVersion = [GADRequest sdkVersion];
  @try {
    NSUInteger versionIndex = [sdkVersion rangeOfString:@"-v"].location + 1;
    version = [sdkVersion substringFromIndex:versionIndex];
    version = [version stringByReplacingOccurrencesOfString:@"." withString:@""];

  } @catch (NSException *exception) {
    NSLog(@"Unable to parse AdMob SDK version");
    version = @"";
  }
  return version;
}

@end
