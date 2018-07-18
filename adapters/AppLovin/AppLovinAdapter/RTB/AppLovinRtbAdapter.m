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

#import <AppLovinSDK/AppLovinSDK.h>

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
    
    self.sdk = [ALSdk shared];
}

+ (void)updateConfiguration:(GADMediationServerConfiguration *)configuration {
    // Pass additional info through to SDK for upcoming request, etc.
    
    [GADMAdapterAppLovinUtils log: @"Updating configuration: %@", configuration];
//    self.configuration = configuration;
//    self.sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials: configuration.credentials];
//
//    if (!self.sdk) {
//        [GADMAdapterAppLovinUtils log:@"Failed to initialize SDK"];
//    }
}

+ (GADVersionNumber)adapterVersion {
    return [GADMAdapterAppLovinUtils toGADVersionNumber:GADMAdapterAppLovinConstant.adapterVersion];
}

+ (GADVersionNumber)adSDKVersion {
    return [GADMAdapterAppLovinUtils toGADVersionNumber:ALSdk.version];
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return [GADMAdapterAppLovinExtras class];
}

- (void)collectSignalsForRequestParameters:(nonnull GADMediationRequestParameters *)params
                         completionHandler:(nonnull GADRTBSignalCompletionHandler)handler {
    self.signalCompletionHandler = handler;
    NSString *signal = self.sdk.adService.bidToken;
    
    handler(signal, nil);
}

#pragma mark GADRTBAdapter Render Ad

- (void)renderBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                     completionHandler:(GADBannerRenderCompletionHandler)completionHandler {
    self.sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials: adConfiguration.credentials];
    
    GADMAdapterAppLovinExtras *extras = adConfiguration.extras;
    self.sdk.settings.muted = extras.muteAudio;
    
    //completionHandler();
}

- (void)renderInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration
                           completionHandler:(GADInterstitialRenderCompletionHandler)completionHandler {
    self.sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials: adConfiguration.credentials];
    
    GADMAdapterAppLovinExtras *extras = adConfiguration.extras;
    self.sdk.settings.muted = extras.muteAudio;
    
    //completionHandler();
}

- (void)renderRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                         completionHandler:(GADRewardedRenderCompletionHandler)completionHandler {
    self.sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials: adConfiguration.credentials];
    
    GADMAdapterAppLovinExtras *extras = adConfiguration.extras;
    self.sdk.settings.muted = extras.muteAudio;
    
    //completionHandler();
}

- (void)renderNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                       completionHandler:(GADNativeRenderCompletionHandler)completionHandler {
    self.sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials: adConfiguration.credentials];
    
    GADMAdapterAppLovinExtras *extras = adConfiguration.extras;
    self.sdk.settings.muted = extras.muteAudio;
    
    //completionHandler();
}

@end
