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

#import <AppLovinSDK/AppLovinSDK.h>

@interface AppLovinRtbAdapter ()
// Controlled Properties
@property (nonatomic, copy) GADMediationServerConfiguration *configuration;
@property (nonatomic, copy) GADRTBSignalCompletionHandler signalCompletionHandler;

@property (nonatomic, strong) GADMAppLovinRtbBannerRenderer *bannerRenderer;
@property (nonatomic, strong) GADMAppLovinRtbInterstitialRenderer *interstitialRenderer;
@property (nonatomic, strong) GADMAppLovinRtbRewardedRenderer *rewardedRenderer;
@end

@implementation AppLovinRtbAdapter

static NSString *const kAppLovinRtbAdapterErrorDomain = @"com.applovin.AppLovinRtbAdapter";
static NSMutableSet<ALSdk *> *ALGlobalSdkSet;

+ (void)initialize {
    [super initialize];
    
    ALGlobalSdkSet = [NSMutableSet set];
}

- (void)dealloc {
    self.bannerRenderer = nil;
    self.interstitialRenderer = nil;
    self.rewardedRenderer = nil;
}

#pragma mark GADRTBAdapter

+ (void)setUp {}

+ (void)updateConfiguration:(GADMediationServerConfiguration *)configuration {
    //Initialize sdk(s) from configuration
    for (GADMediationCredentials *credentials in configuration.credentials) {
        ALSdk *sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials:credentials.settings];
        [ALGlobalSdkSet addObject:sdk];
    }
}

+ (GADVersionNumber)adapterVersion {
    NSString *versionString = GADMAdapterAppLovinConstant.adapterVersion;
    NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
    
    GADVersionNumber version = {0};
    if (versionComponents.count == 4) {
        version.majorVersion = [versionComponents[0] integerValue];
        version.minorVersion = [versionComponents[1] integerValue];
        // Adapter versions have 2 patch versions. Multiply the first patch by 100.
        version.patchVersion = [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
    }
    return version;
}

+ (GADVersionNumber)adSDKVersion {
    NSString *versionString = ALSdk.version;
    NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
    
    GADVersionNumber version = {0};
    if (versionComponents.count == 3) {
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
    
    if (params) {
        [GADMAdapterAppLovinUtils log:@"Extras for signal collection: %@", params.extras];
    }
    
    ALSdk *sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials:params.credentials.settings];
    NSString *signal = sdk.adService.bidToken;
    
    if ( signal.length > 0 ) {
        [GADMAdapterAppLovinUtils log:@"Generated bid token %@", signal];
        handler(signal, nil);
    } else {
        NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.rtbErrorDomain
                                             code:kGADErrorMediationAdapterError
                                         userInfo:@{
                                                    NSLocalizedFailureReasonErrorKey : @"Failed to generate bid token"
                                                    }];
        [GADMAdapterAppLovinUtils log:@"Failed to generate bid token"];
        handler(nil, error);
    }
}

#pragma mark GADRTBAdapter Render Ad

- (void)renderBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                     completionHandler:(GADBannerRenderCompletionHandler)completionHandler {
    self.bannerRenderer = [[GADMAppLovinRtbBannerRenderer alloc] initWithAdConfiguration:adConfiguration
                                                                       completionHandler:completionHandler];
    [self.bannerRenderer loadAd];
}

- (void)renderInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration
                           completionHandler:(GADInterstitialRenderCompletionHandler)completionHandler {
    self.interstitialRenderer = [[GADMAppLovinRtbInterstitialRenderer alloc] initWithAdConfiguration:adConfiguration
                                                                                   completionHandler:completionHandler];
    [self.interstitialRenderer loadAd];
}

- (void)renderRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                         completionHandler:(GADRewardedRenderCompletionHandler)completionHandler {
    self.rewardedRenderer = [[GADMAppLovinRtbRewardedRenderer alloc] initWithAdConfiguration:adConfiguration
                                                                           completionHandler:completionHandler];
    [self.rewardedRenderer loadAd];
}

@end
