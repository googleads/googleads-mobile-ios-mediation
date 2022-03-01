//
//  GADVpadnDefinition.h
//  VponAdapter
//
//  Created by Yi-Hsiang, Chien on 2020/2/3.
//  Copyright © 2020 Vpon. All rights reserved.
//

@import Foundation;
@import GoogleMobileAds;
@import VpadnSDKAdKit;

#define VPADN_LIMIT_VERSION @"vpadn-sdk-i-v5.2.0"
#define VPADN_ADMOB_ADAPTER_VERSION @"2.0.6"

#define VpadnAdmobFmt(fmt, ...) NSLog((@"<VPON> [NOTE] [MEDIATION] " fmt), ##__VA_ARGS__);

NS_ASSUME_NONNULL_BEGIN

@interface GADVpadnDefinition : NSObject

+ (void) adapterNote;

+ (NSError *) defaultError;

+ (BOOL) verifyVersion;

@end

NS_ASSUME_NONNULL_END
