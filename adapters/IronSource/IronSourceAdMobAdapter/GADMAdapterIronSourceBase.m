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


#import "GADMAdapterIronSourceBase.h"

@implementation GADMAdapterIronSourceBase 
// IronSource internal reporting const
NSString *const kGADMMediationName = @"AdMob";
// IronSource parameters keys
NSString *const kGADMAdapterIronSourceAppKey = @"appKey";
NSString *const kGADMAdapterIronSourceIsTestEnabled = @"isTestEnabled";

#pragma mark - Admob

+ (NSString *)adapterVersion {
    return [IronSource sdkVersion];
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return [GADMIronSourceExtras class];
}

- (void)stopBeingDelegate {
    [self onLog:@"stopBeingDelegate"];
}

#pragma mark Utils Methods

- (void)initIronSourceSDKWithAppKey:(NSString *)appKey adUnit:(NSString *)adUnit {
    // 1 - We are not sending user ID from adapters anymore,
    //     the IronSource SDK will take care of this identifier
    // 2 - We assume the init is always successful (we will fail in load if needed)
    [self onLog:@"initIronSourceSDKWithAppKey"];
    [IronSource setMediationType:kGADMMediationName];
    [IronSource initWithAppKey:appKey adUnits:@[adUnit]];
}

- (void)onLog: (NSString *)log {
    //if (self.isTestEnabled) {
        NSLog(@"IronSourceAdapter: %@" , log);
   // }
}

-(BOOL)isEmpty:(id)value
{
    return value == nil
        || [value isKindOfClass:[NSNull class]]
        || ([value respondsToSelector:@selector(length)] && [(NSString *)value length] == 0)
        || ([value respondsToSelector:@selector(length)] && [(NSData *)value length] == 0)
        || ([value respondsToSelector:@selector(count)] && [(NSArray *)value count] == 0);
}

- (NSError *)createErrorWith:(NSString *)description andReason:(NSString *)reason andSuggestion:(NSString *)suggestion {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: NSLocalizedString(description, nil),
                               NSLocalizedFailureReasonErrorKey: NSLocalizedString(reason, nil),
                               NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(suggestion, nil)
                               };
    
    return [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:userInfo];
}


@end
