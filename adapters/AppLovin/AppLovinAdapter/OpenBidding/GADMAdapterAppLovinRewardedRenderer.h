//
//  GADMRTBAdapterAppLovinRewardedRenderer.h
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import <AppLovinSDK/AppLovinSDK.h>
#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

/// Wrapper for AppLovin's rewarded ad. Used to request and present rewarded ads from AppLovin SDK.
@interface GADMAdapterAppLovinRewardedRenderer : NSObject <GADMediationRewardedAd>

/// Callback object to notify the Google Mobile Ads SDK if ad rendering succeeded or failed.
@property(nonatomic, copy, nonnull, readonly)
    GADMediationRewardedLoadCompletionHandler adLoadCompletionHandler;

/// Delegate to notify the Google Mobile Ads SDK of rewarded presentation events.
@property(nonatomic, weak, nullable) id<GADMediationRewardedAdEventDelegate> delegate;

/// An AppLovin rewarded ad.
@property(nonatomic, nullable) ALAd *ad;

/// The AppLovin zone identifier used to load an ad.
@property(nonatomic, copy, nullable, readonly) NSString *zoneIdentifier;

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)handler;
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Request a rewarded ad from AppLovin SDK.
- (void)requestRewardedAd;

@end
