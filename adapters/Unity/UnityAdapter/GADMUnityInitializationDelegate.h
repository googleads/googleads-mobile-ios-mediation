//
//  GADMUnityInitializationDelegate.h
//  AdMob-TestApp-Local
//
//  Created by Kavya Katooru on 6/25/20.
//  Copyright © 2020 Unity Ads. All rights reserved.
//

#import <Foundation/Foundation.h>
@import GoogleMobileAds;
@import UnityAds;

@interface GADMUnityInitializationDelegate : NSObject {
    GADMediationAdapterSetUpCompletionBlock initCompletionBlock;
}

- (instancetype)initWithCompletionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler;

@end

