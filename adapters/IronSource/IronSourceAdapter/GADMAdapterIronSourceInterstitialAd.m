//
//  GADMAdapterIronSourceInterstitialAd.m
//  ISMedAdapters
//
//  Created by alond on 13/12/2022.
//  Copyright © 2022 ironSource Ltd. All rights reserved.
//

#import "GADMAdapterIronSourceInterstitialAd.h"
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceInterstitialDelegate.h"
#import "GADMAdapterIronSourceUtils.h"
#import "GADMediationAdapterIronSource.h"
#import "ISMediationManager.h"

@interface GADMAdapterIronSourceInterstitialAd () <GADMediationInterstitialAd,GADMAdapterIronSourceInterstitialDelegate,ISDemandOnlyInterstitialDelegate>

// The completion handler to call when the ad loading succeeds or fails.
@property(copy, nonatomic) GADMediationInterstitialLoadCompletionHandler adLoadCompletionHandler;

// Ad configuration for the ad to be rendered.
@property(weak, nonatomic) GADMediationAdConfiguration *adConfiguration;

// An ad event delegate to invoke when ad rendering events occur.
@property(weak, nonatomic) id<GADMediationInterstitialAdEventDelegate> adEventDelegate;

/// Holds the ID of the ad instance to be presented.
@property(nonatomic, copy) NSString *instanceID;

/// Holds the state of the ad instance to be presented.
@property(nonatomic, copy) NSString *instanceState;

@end

@implementation GADMAdapterIronSourceInterstitialAd

#pragma mark Admob GADMediationAdapter

- (instancetype)initWithGADMediationInterstitialAdConfiguration:(GADMediationInterstitialAdConfiguration*)adConfiguration
                                              completionHandler:(GADMediationInterstitialLoadCompletionHandler)
                                                                completionHandler {
  self = [super init];
  if (self) {
    _adLoadCompletionHandler = completionHandler;
    _adConfiguration = adConfiguration;
    // Default instance ID
    self.instanceID = GADMIronSourceDefaultInstanceId;
    // Default instance state
    self.instanceState = GADMAdapterIronSourceInstanceStateStart;
  }
    
  return self;
}

-(void)requestInterstitial{
    NSDictionary *credentials = [_adConfiguration.credentials settings];

    /* Parse application key */
    NSString *applicationKey = @"";
    if (credentials[GADMAdapterIronSourceAppKey]) {
      applicationKey = credentials[GADMAdapterIronSourceAppKey];
    }

    if ([GADMAdapterIronSourceUtils isEmpty:applicationKey]) {
      NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
          GADMAdapterIronSourceErrorInvalidServerParameters,
          @"'appKey' parameter is missing. Make sure that appKey' server parameter is added.");
      _adLoadCompletionHandler(nil, error);
      return;
    }
    
    if (credentials[GADMAdapterIronSourceInstanceId]) {
      self.instanceID = credentials[GADMAdapterIronSourceInstanceId];
    }

    [[ISMediationManager sharedManager]
        initIronSourceSDKWithAppKey:applicationKey
                         forAdUnits:[NSSet setWithObject:IS_INTERSTITIAL]];
    [[ISMediationManager sharedManager] loadInterstitialAdWithDelegate:self instanceID:self.instanceID];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    [[ISMediationManager sharedManager] presentInterstitialAdFromViewController:viewController instanceID:_instanceID];
}

- (void)didClickInterstitial:(NSString *)instanceId {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:@"Did click IronSource Interstitial for Instance ID: %@",
                                         instanceId]];
    [_adEventDelegate reportClick];
}

- (void)interstitialDidClose:(NSString *)instanceId {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:@"IronSource Interstitial did close for Instance ID: %@",
                                         instanceId]];
    id<GADMediationInterstitialAdEventDelegate> strongDelegate = _adEventDelegate;
    [strongDelegate willDismissFullScreenView];
    [strongDelegate didDismissFullScreenView];
}

- (void)interstitialDidFailToLoadWithError:(NSError *)error
                                instanceId:(NSString *)instanceId {
    _adLoadCompletionHandler(nil, error);
}

- (void)interstitialDidFailToShowWithError:(NSError *)error
                                instanceId:(NSString *)instanceId {
    [_adEventDelegate didFailToPresentWithError:error];
}

- (void)interstitialDidLoad:(NSString *)instanceId {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:@"InterstitialDidLoad for Instance ID: %@", instanceId]];
    _adEventDelegate = _adLoadCompletionHandler(self, nil);
}

- (void)interstitialDidOpen:(NSString *)instanceId {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:@"IronSource Interstitial did open for Instance ID: %@",
                                         instanceId]];

    id<GADMediationInterstitialAdEventDelegate> strongDelegate = _adEventDelegate;
    [strongDelegate willPresentFullScreenView];
    [strongDelegate reportImpression];
}

- (void)setState:(NSString *)state {
  [GADMAdapterIronSourceUtils
      onLog:[NSString
                stringWithFormat:@"Interstitial Instance setState: changing from oldState=%@ to newState=%@",
                                 self.instanceState, state]];
  self.instanceState = state;
}

- (NSString *)getState {
    return self.instanceState;
}

@end
