//
//  GADCHBRewarded.m
//  Adapter
//
//  Created by Daniel Barros on 03/03/2020.
//  Copyright © 2020 Google. All rights reserved.
//

#import "GADCHBRewarded.h"
#import "GADMChartboostError.h"

@interface GADCHBRewarded () <CHBRewardedDelegate>
@end


@implementation GADCHBRewarded {
    GADMediationRewardedLoadCompletionHandler _loadCompletionHandler;
    __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;
    CHBRewarded *_ad;
    BOOL _adIsShown;
}

- (instancetype)initWithLocation:(NSString *)location
                       mediation:(CHBMediation *)mediation
                 adConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
               completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler
{
    self = [super init];
    if (self) {
        _loadCompletionHandler = completionHandler;
        _ad = [[CHBRewarded alloc] initWithLocation:location
                                          mediation:mediation
                                           delegate:self];
        _adIsShown = NO;
    }
    return self;
}

- (void)destroy
{
    _loadCompletionHandler = nil;
    _adEventDelegate = nil;
    _ad = nil;
}

- (void)load
{
    [_ad cache];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController
{
    [_ad showFromViewController:viewController];
}

- (void)completeLoadWithError:(nullable CHBCacheError *)error
{
    if (!_loadCompletionHandler) {
        return;
    }
    if (error) {
        // TODO: Proper error mapping
        _loadCompletionHandler(nil, NSErrorForCHBCacheError(error));
    } else {
        _adEventDelegate = _loadCompletionHandler(self, nil);
    }
    _loadCompletionHandler = nil;
}

// MARK: - CHBRewardedDelegate

- (void)didCacheAd:(CHBCacheEvent *)event error:(nullable CHBCacheError *)error
{
    [self completeLoadWithError:error];
}

- (void)willShowAd:(CHBShowEvent *)event
{
    
}

- (void)didShowAd:(CHBShowEvent *)event error:(nullable CHBShowError *)error
{
    id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
    if (error) {
        // if the ad is shown Chartboost will proceed to dismiss it and the rest is handled in didDismissAd:
        if (!_adIsShown) {
            // TODO: Proper error mapping
            [strongDelegate didFailToPresentWithError:NSErrorForCHBShowError(error)];
        }
    } else {
        _adIsShown = YES;
        [strongDelegate willPresentFullScreenView];
        [strongDelegate reportImpression];
        [strongDelegate didStartVideo];
    }
}

- (void)didClickAd:(CHBClickEvent *)event error:(nullable CHBClickError *)error
{
    [_adEventDelegate reportClick];
}

- (void)didFinishHandlingClick:(CHBClickEvent *)event error:(nullable CHBClickError *)error
{
    
}

- (void)didDismissAd:(CHBDismissEvent *)event
{
    _adIsShown = NO;
    id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
    [strongDelegate willDismissFullScreenView];
    [strongDelegate didDismissFullScreenView];
}

- (void)didEarnReward:(CHBRewardEvent *)event
{
    id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
    [strongDelegate didEndVideo];
    NSDecimalNumber *reward = [[NSDecimalNumber alloc] initWithInt:event.reward];
    GADAdReward *gadReward = [[GADAdReward alloc] initWithRewardType:@"" rewardAmount:reward];
    [strongDelegate didRewardUserWithReward:gadReward];
}

@end
