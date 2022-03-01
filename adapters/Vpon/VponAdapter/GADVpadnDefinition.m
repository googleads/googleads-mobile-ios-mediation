//
//  GADVpadnDefinition.m
//  VponAdapter
//
//  Created by Yi-Hsiang, Chien on 2020/2/3.
//  Copyright © 2020 Vpon. All rights reserved.
//

#import "GADVpadnDefinition.h"

@implementation GADVpadnDefinition

+ (void) adapterNote {
    VpadnAdmobFmt(@"Admob Version: %@", [GADMobileAds sharedInstance].sdkVersion);
    VpadnAdmobFmt(@"Adapter Version: %@", VPADN_ADMOB_ADAPTER_VERSION);
}

+ (NSError *) defaultError {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"No ads", NSLocalizedFailureReasonErrorKey: @"No ads"};
    return [NSError errorWithDomain:@"com.vpon.vpadnsdk" code:-999 userInfo:userInfo];
}

+ (BOOL) verifyVersion {
    BOOL result = [self inspectVersion:[VpadnAdRequest sdkVersion] isLargerEqualThanVersion:VPADN_LIMIT_VERSION];
    if (!result) {
        VpadnAdmobFmt(@"The version of VpadnSDKAdKit must greater than %@", VPADN_LIMIT_VERSION);
    }
    return result;
}

+ (BOOL) inspectVersion:(NSString *)actualVersion isLargerEqualThanVersion:(NSString *)requiredVersion {
    requiredVersion = [[requiredVersion copy] stringByReplacingOccurrencesOfString:@"vpadn-sdk-i-v" withString:@""];
    actualVersion = [[actualVersion copy] stringByReplacingOccurrencesOfString:@"vpadn-sdk-i-v" withString:@""];

    NSArray *requiredComponents = [requiredVersion componentsSeparatedByString:@"."];
    NSArray *actualComponents = [actualVersion componentsSeparatedByString:@"."];

    for (NSInteger index = 0; index < requiredComponents.count; index++) {
        if ([actualComponents count] <= index) {
            break;
        }
        NSString *requiredSplitVersion = (NSString *)requiredComponents[index];
        NSString *actualSplitVersion = (NSString *)actualComponents[index];
        NSComparisonResult result = [requiredSplitVersion compare:actualSplitVersion options:NSNumericSearch];
        if (result == NSOrderedAscending) {
            break;
        } else if (result == NSOrderedSame) {
            continue;
        } else {
            return NO;
        }
    }
    return YES;
}

@end
