// Copyright 2020 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMMaioInterstitialAdapter.h"

#import <Maio/Maio-Swift.h>

#import "GADMAdapterMaioUtils.h"
#import "GADMMaioConstants.h"

@interface GADMMaioInterstitialAdapter () <MaioInterstitialLoadCallback, MaioInterstitialShowCallback>

@property(nonatomic, weak) id<GADMAdNetworkConnector> interstitialAdConnector;

@property(nonatomic, strong) NSString *zoneId;
@property(nonatomic, strong) MaioInterstitial *interstitial;

@end

@implementation GADMMaioInterstitialAdapter

#pragma mark - GADMAdNetworkAdapter

/// Returns a version string for the adapter. It can be any string that uniquely
/// identifies the version of your adapter. For example, "1.0", or simply a date
/// such as "20110915".
+ (NSString *)adapterVersion {
  return GADMMaioAdapterVersion;
}

/// The extras class that is used to specify additional parameters for a request
/// to this ad network. Returns Nil if the network does not have extra settings
/// for publishers to send.
+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return nil;
}

/// Designated initializer. Implementing classes can and should keep the
/// connector in an instance variable. However you must never retain the
/// connector, as doing so will create a circular reference and cause memory
/// leaks.
- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }

  self = [super init];
  if (self) {
    self.interstitialAdConnector = connector;
  }
  return self;
}

/// Asks the adapter to initiate a banner ad request. The adapter does not need
/// to return anything. The assumption is that the adapter will start an
/// asynchronous ad fetch over the network. Your adapter may act as a delegate
/// to your SDK to listen to callbacks. If your SDK does not support the given
/// ad size, or does not support banner ads, call back to the adapter:didFailAd:
/// method of the connector.
- (void)getBannerWithSize:(GADAdSize)adSize {
  // not supported bunner
  NSString *description =
      [NSString stringWithFormat:@"%@ does not supported banner.", [self class]];
  NSError *error = GADMAdapterMaioErrorWithCodeAndDescription(
      GADMAdapterMaioErrorAdFormatNotSupported, description);
  [self.interstitialAdConnector adapter:self didFailAd:error];
}

/// Asks the adapter to initiate an interstitial ad request. The adapter does
/// not need to return anything. The assumption is that the adapter will start
/// an asynchronous ad fetch over the network. Your adapter may act as a
/// delegate to your SDK to listen to callbacks. If your SDK does not support
/// interstitials, call back to the adapter:didFailInterstitial: method of the
/// connector.
- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = self.interstitialAdConnector;
  NSDictionary *param = [strongConnector credentials];
  if (!param) {
    return;
  }
  self.zoneId = param[GADMMaioAdapterZoneIdKey];

  MaioRequest *request = [[MaioRequest alloc] initWithZoneId:self.zoneId
                                                    testMode:strongConnector.testMode];
  self.interstitial = [MaioInterstitial loadAdWithRequest:request callback:self];
}

/// When called, the adapter must remove itself as a delegate or notification
/// observer from the underlying ad network SDK. You should also call this
/// method in your adapter dealloc, so when your adapter goes away, your SDK
/// will not call a freed object. This function should be idempotent and should
/// not crash regardless of when or how many times the method is called.
- (void)stopBeingDelegate {
}

/// Some ad transition types may cause issues with particular Ad SDKs. The
/// adapter may decide whether the given animation type is OK. Defaults to YES.
- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  // default value
  return YES;
}

/// Present an interstitial using the supplied UIViewController, by calling
/// presentViewController:animated:completion:.
///
/// Your interstitial should not immediately present itself when it is received.
/// Instead, you should wait until this method is called on your adapter to
/// present the interstitial.
///
/// Make sure to call adapterWillPresentInterstitial: on the connector when the
/// interstitial is about to be presented, and adapterWillDismissInterstitial:
/// and adapterDidDismissInterstitial: when the interstitial is being dismissed.
- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  [self.interstitialAdConnector adapterWillPresentInterstitial:self];
  [self.interstitial showWithViewContext:rootViewController callback:self];
}

#pragma mark - MaioInterstitialLoadCallback, MaioInterstitialShowCallback

- (void)didLoad:(MaioInterstitial *)ad {
  [self.interstitialAdConnector adapterDidReceiveInterstitial:self];

}

- (void)didFail:(MaioInterstitial *)ad errorCode:(NSInteger)errorCode {
  id<GADMAdNetworkConnector> strongConnector = self.interstitialAdConnector;
  if (!strongConnector) {
    return;
  }
  NSString *description = @"maio SDK returned an error";
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMMaioSDKErrorDomain
                                       code:errorCode
                                   userInfo:userInfo];

  NSLog(@"MaioInterstitial did fail. error: %@", error);

  if (10000 <= errorCode && errorCode < 20000) {
    // Fail to load.
    [strongConnector adapter:self didFailAd:error];
  } else if (20000 <= errorCode && errorCode < 30000) {
    // Fail to Show
    [strongConnector adapter:self didFailAd:error];
  } else {
    // Unknown error code
    [strongConnector adapter:self didFailAd:error];
  }
}

- (void)didOpen:(MaioInterstitial *)ad {
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)didClose:(MaioInterstitial *)ad {
  id<GADMAdNetworkConnector> strongConnector = self.interstitialAdConnector;
  if (!strongConnector) {
    return;
  }

  [strongConnector adapterWillDismissInterstitial:self];
  [strongConnector adapterDidDismissInterstitial:self];
}

#pragma mark - private methods

@end
