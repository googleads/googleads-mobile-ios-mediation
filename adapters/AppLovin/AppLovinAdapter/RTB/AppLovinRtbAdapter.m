//
//  AppLovinRtbAdapter.m
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import "AppLovinRtbAdapter.h"
#import "GADMAdapterAppLovinExtras.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAppLovinRtbBannerRenderer.h"
#import "GADMAppLovinRtbInterstitialRenderer.h"
#import "GADMAppLovinRtbRewardedRenderer.h"
#import "GADMAppLovinRtbNativeRenderer.h"

#import <AppLovinSDK/AppLovinSDK.h>

static NSString *const kAppLovinRtbAdapterErrorDomain = "com.applovin.AppLovinRtbAdapter";

@interface AppLovinRtbAdapter ()
// Controlled Properties
@property (nonatomic, strong) ALSdk *sdk;
@property (nonatomic, copy) GADMediationServerConfiguration *configuration;
@property (nonatomic, copy) GADRTBSignalCompletionHandler signalCompletionHandler;
@end

@implementation AppLovinRtbAdapter

- (void)dealloc {
    
}

#pragma mark GADRTBAdapter

+ (void)setUp {
    [GADMAdapterAppLovinUtils log: @"Setting up sdk..."];
    
    //TODO: find a way to init sdk by key, passed down from publisher
    self.sdk = [ALSdk shared];
}

+ (void)updateConfiguration:(GADMediationServerConfiguration *)configuration {
    self.configuration = configuration;
}

+ (GADVersionNumber)adapterVersion {
    NSString *version = GADMAdapterAppLovinConstant.adapterVersion;
    NSArray *versionComponents = [sdkVersion componentsSeparatedByString:@"."];
    
    GADVersionNumber version = {0};
    if ( versionComponents.count == 4 )
    {
        version.majorVersion = [versionComponents[0] integerValue];
        version.minorVersion = [versionComponents[1] integerValue];
        // Adapter versions have 2 patch versions. Multiply the first patch by 100.
        version.patchVersion = [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
    }
    return version;
}

+ (GADVersionNumber)adSDKVersion {
    NSString *version = ALSdk.version;
    NSArray *versionComponents = [sdkVersion componentsSeparatedByString:@"."];
    
    GADVersionNumber version = {0};
    if ( versionComponents.count == 3 )
    {
        version.majorVersion = [versionComponents[0] integerValue];
        version.minorVersion = [versionComponents[1] integerValue];
        version.patchVersion = [versionComponents[2] integerValue];
    }
    return version;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return [GADMAdapterAppLovinExtras class];
}

- (void)collectSignalsForRequestParameters:(nonnull GADMediationRequestParameters *)params
                         completionHandler:(nonnull GADRTBSignalCompletionHandler)handler {
    self.signalCompletionHandler = handler;
    
    if ( params )
    {
        [GADMAdapterAppLovinUtils log: @"Extras for signal collection: %@", params.extras];
    }
    
    NSString *signal = self.sdk.adService.bidToken;
    if ( signal.length > 0 ) {
        [GADMAdapterAppLovinUtils log: @"Generated bid token %@", signal];
        handler(signal, nil);
    } else {
        //create our own errorcode?
        NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.rtbErrorDomain
                                             code:kGADErrorMediationAdapterError
                                         userInfo:@{
                                                    NSLocalizedFailureReasonErrorKey : @"Failed to generate bid token"
                                                    }];
        [GADMAdapterAppLovinUtils log: @"Failed to generate bid token"];
        handler(nil, error);
    }
}

#pragma mark GADRTBAdapter Render Ad

- (void)renderBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                     completionHandler:(GADBannerRenderCompletionHandler)completionHandler {
    GADMAppLovinRtbBannerRenderer *bannerRenderer = [[GADMAppLovinRtbBannerRenderer alloc] initWithAdConfiguration: adConfiguration
                                                                                                 completionHandler: completionHandler];
    [bannerRenderer loadAd];
}

- (void)renderInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration
                           completionHandler:(GADInterstitialRenderCompletionHandler)completionHandler {
    GADMAppLovinRtbInterstitialRenderer *interstitialRenderer = [[GADMAppLovinRtbInterstitialRenderer alloc] initWithAdConfiguration: adConfiguration
                                                                                                                   completionHandler: completionHandler];
    [interstitialRenderer loadAd];
}

- (void)renderRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                         completionHandler:(GADRewardedRenderCompletionHandler)completionHandler {
    GADMAppLovinRtbRewardedRenderer *rewardedRenderer = [[GADMAppLovinRtbRewardedRenderer alloc] initWithAdConfiguration: adConfiguration
                                                                                                       completionHandler: completionHandler];
    [rewardedRenderer loadAd];
}

- (void)renderNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                       completionHandler:(GADNativeRenderCompletionHandler)completionHandler {
    GADMediationNativeAdConfiguration *nativeRenderer = [[GADMediationNativeAdConfiguration alloc] initWithAdConfiguration: adConfiguration
                                                                                                         completionHandler: completionHandler];
    [nativeRenderer loadAd];
}

@end
