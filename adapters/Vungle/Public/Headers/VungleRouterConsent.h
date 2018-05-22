//
//  VungleRouterConsent.h
//  VungleAdapter
//
//  Created by Vungle on 5/18/18.
//  Copyright © 2018 Vungle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VungleSDK/VungleSDK.h>

@interface VungleRouterConsent : NSObject
+ (void)updateConsentStatus:(VungleConsentStatus)consentStatus;
+ (VungleConsentStatus)getConsentStatus;
@end
