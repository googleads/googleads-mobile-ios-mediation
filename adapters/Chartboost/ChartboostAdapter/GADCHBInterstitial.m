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
                       connector:(id<GADMAdNetworkConnector>)connector {
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

- (void)destroy {
  _networkAdapter = nil;
  _connector = nil;
  _ad = nil;
}

- (void)load {
  [_ad cache];
}

- (void)showFromViewController:(UIViewController *)viewController {
  [_ad showFromViewController:viewController];
}

// MARK: - CHBInterstitialDelegate

- (void)didCacheAd:(CHBCacheEvent *)event error:(nullable CHBCacheError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _networkAdapter;
  if (error) {
    [strongConnector adapter:strongAdapter didFailAd:NSErrorForCHBCacheError(error)];
  } else {
    [strongConnector adapterDidReceiveInterstitial:strongAdapter];
  }
}

- (void)willShowAd:(CHBShowEvent *)event {
}

- (void)didShowAd:(CHBShowEvent *)event error:(nullable CHBShowError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _networkAdapter;
  if (error) {
    // if the ad is shown Chartboost will proceed to dismiss it and the rest is handled in didDismissAd:
    if (!_adIsShown) {
      [strongConnector adapterWillPresentInterstitial:strongAdapter];
      [strongConnector adapterWillDismissInterstitial:strongAdapter];
      [strongConnector adapterDidDismissInterstitial:strongAdapter];
    }
  } else {
    _adIsShown = YES;
    [strongConnector adapterWillPresentInterstitial:strongAdapter];
  }
}

- (void)didClickAd:(CHBClickEvent *)event error:(nullable CHBClickError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _networkAdapter;
  [strongConnector adapterDidGetAdClick:strongAdapter];
  // TODO: Need to call this even if showing an in-app browser?
  if (!error) {
    [strongConnector adapterWillLeaveApplication:strongAdapter];
  }
}

- (void)didFinishHandlingClick:(CHBClickEvent *)event error:(nullable CHBClickError *)error {
}

- (void)didDismissAd:(CHBDismissEvent *)event {
  _adIsShown = NO;
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _networkAdapter;
  [strongConnector adapterWillDismissInterstitial:strongAdapter];
  [strongConnector adapterDidDismissInterstitial:strongAdapter];
}

@end
