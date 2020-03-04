//
//  GADCHBInterstitial.m
//  Adapter
//
//  Created by Daniel Barros on 02/03/2020.
//  Copyright © 2020 Google. All rights reserved.
//

#import "GADCHBInterstitial.h"
#import "GADMChartboostError.h"

@interface GADCHBInterstitial () <CHBInterstitialDelegate>
@end

@implementation GADCHBInterstitial {
    __weak id<GADMAdNetworkAdapter> _networkAdapter;
    __weak id<GADMAdNetworkConnector> _connector;
    CHBInterstitial *_ad;
    BOOL _adIsShown;
}

- (instancetype)initWithLocation:(NSString *)location
                       mediation:(CHBMediation *)mediation
                  networkAdapter:(id<GADMAdNetworkAdapter>)networkAdapter
                       connector:(id<GADMAdNetworkConnector>)connector
{
    self = [super init];
    if (self) {
        _networkAdapter = networkAdapter;
        _connector = connector;
        _ad = [[CHBInterstitial alloc] initWithLocation:location
                                              mediation:mediation
                                               delegate:self];
        _adIsShown = NO;
    }
    return self;
}

- (void)destroy
{
    _networkAdapter = nil;
    _connector = nil;
    _ad = nil;
}

- (void)load
{
    [_ad cache];
}

- (void)showFromViewController:(UIViewController *)viewController
{
    [_ad showFromViewController:viewController];
}

// MARK: - CHBInterstitialDelegate

- (void)didCacheAd:(CHBCacheEvent *)event error:(nullable CHBCacheError *)error
{
    if (error) {
        [_connector adapter:_networkAdapter didFailAd:NSErrorForCHBCacheError(error)];
    } else {
        [_connector adapterDidReceiveInterstitial:_networkAdapter];
    }
}

- (void)willShowAd:(CHBShowEvent *)event
{
    
}

- (void)didShowAd:(CHBShowEvent *)event error:(nullable CHBShowError *)error
{
    if (error) {
        // if the ad is shown Chartboost will proceed to dismiss it and the rest is handled in didDismissAd:
        if (!_adIsShown) {
            [_connector adapterWillPresentInterstitial:_networkAdapter];
            [_connector adapterWillDismissInterstitial:_networkAdapter];
            [_connector adapterDidDismissInterstitial:_networkAdapter];
        }
    } else {
        _adIsShown = YES;
        [_connector adapterWillPresentInterstitial:_networkAdapter];
    }
}

- (void)didClickAd:(CHBClickEvent *)event error:(nullable CHBClickError *)error
{
    [_connector adapterDidGetAdClick:_networkAdapter];
    if (!error) {
        [_connector adapterWillLeaveApplication:_networkAdapter];
    }
}

- (void)didFinishHandlingClick:(CHBClickEvent *)event error:(nullable CHBClickError *)error
{
    
}

- (void)didDismissAd:(CHBDismissEvent *)event
{
    _adIsShown = NO;
    [_connector adapterWillDismissInterstitial:_networkAdapter];
    [_connector adapterDidDismissInterstitial:_networkAdapter];
}

@end
