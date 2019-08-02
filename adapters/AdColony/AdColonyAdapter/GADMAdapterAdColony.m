//
// Copyright 2016, AdColony, Inc.
//

#import "GADMAdapterAdColony.h"
#import "GADMAdapterAdColonyConstants.h"
#import "GADMAdapterAdColonyExtras.h"
#import "GADMAdapterAdColonyHelper.h"
#import "GADMAdapterAdColonyInitializer.h"
#import "GADMediationAdapterAdColony.h"

#import <AdColony/AdColony.h>

#define DEBUG_LOGGING 0

#if DEBUG_LOGGING
#define NSLogDebug(...) NSLog(__VA_ARGS__)
#else
#define NSLogDebug(...)
#endif

@interface GADMAdapterAdColony ()

@property AdColonyInterstitial *ad;
@property NSString *appId;
@property NSString *currentZone;
@property NSArray *zones;
@property(weak) id<GADMAdNetworkConnector> connector;

@end

@implementation GADMAdapterAdColony

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterAdColony class];
}

+ (NSString *)adapterVersion {
  return kGADMAdapterAdColonyVersionString;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return GADMAdapterAdColonyExtras.class;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  if (self = [super init]) {
    self.connector = connector;
    NSDictionary *credentials = [connector credentials];
    self.appId = credentials[kGADMAdapterAdColonyAppIDkey];
  }
  return self;
}

#pragma mark - Interstitial

- (void)getInterstitial {
  GADMAdapterAdColony *__weak weakSelf = self;
  [GADMAdapterAdColonyHelper
      setupZoneFromConnector:self.connector
                    callback:^(NSString *zone, NSError *error) {
                      GADMAdapterAdColony *strongSelf = weakSelf;
                      if (error && strongSelf) {
                        [strongSelf.connector adapter:strongSelf didFailAd:error];
                        return;
                      }

                      NSLogDebug(@"Zone in interstitial class: %@", zone);
                      [strongSelf getInterstitialFromZoneId:zone withConnector:self.connector];
                    }];
}

- (void)getInterstitialFromZoneId:(NSString *)zone
                    withConnector:(id<GADMAdNetworkConnector>)connector {
  self.ad = nil;

  __weak GADMAdapterAdColony *weakSelf = self;

  AdColonyAdOptions *options = [GADMAdapterAdColonyHelper getAdOptionsFromConnector:connector];

  NSLogDebug(@"getInterstitialFromZoneId: %@", zone);

  [AdColony requestInterstitialInZone:zone
      options:options
      success:^(AdColonyInterstitial *_Nonnull ad) {
        NSLogDebug(@"Retrieve ad: %@", zone);
        weakSelf.ad = ad;
        if (weakSelf.connector) {
          [weakSelf.connector adapterDidReceiveInterstitial:weakSelf];
        }

        // Re-request intersitial when expires, this avoids the situation:
        // 1. Admob interstitial request from zone A. Causes ADC configure to occur with zone A,
        // then ADC ad request from zone A. Both succeed.
        // 2. Admob rewarded video request from zone B. Causes ADC configure to occur with zones A,
        // B, then ADC ad request from zone B. Both succeed.
        // 3. Try to present ad loaded from zone A. It doesn’t show because of error: `No session
        // with id: xyz has been registered. Cannot show interstitial`.
        [ad setExpire:^{
          NSLog(@"AdColonyAdapter [Info]: Interstitial Ad expired from zone: %@ because of "
                @"configuring another Ad. To avoid this situation, use startWithCompletionHandler: "
                @"to initialize Google Mobile Ads SDK and wait for the completion handler to be "
                @"called before requesting an ad.",
                zone);
        }];
      }
      failure:^(AdColonyAdRequestError *_Nonnull err) {
        NSError *error =
            [NSError errorWithDomain:kGADMAdapterAdColonyErrorDomain
                                code:kGADErrorInvalidRequest
                            userInfo:@{NSLocalizedDescriptionKey : err.localizedDescription}];
        if (weakSelf.connector) {
          [weakSelf.connector adapter:weakSelf didFailAd:error];
        }
        NSLog(@"AdColonyAdapter [Info] : Failed to retrieve ad: %@", error.localizedDescription);
      }];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  __weak GADMAdapterAdColony *weakSelf = self;

  [self.ad setOpen:^{
    if (weakSelf.connector) {
      [weakSelf.connector adapterWillPresentInterstitial:weakSelf];
    }
  }];

  [self.ad setClick:^{
    if (weakSelf.connector) {
      [weakSelf.connector adapterDidGetAdClick:weakSelf];
    }
  }];

  [self.ad setClose:^{
    if (weakSelf.connector) {
      [weakSelf.connector adapterWillDismissInterstitial:weakSelf];
      [weakSelf.connector adapterDidDismissInterstitial:weakSelf];
    }
  }];

  [self.ad setLeftApplication:^{
    if (weakSelf.connector) {
      [weakSelf.connector adapterWillLeaveApplication:weakSelf];
    }
  }];

  if (![self.ad showWithPresentingViewController:rootViewController]) {
    NSLog(@"AdColonyAdapter [Info] : Failed to show ad.");
  }
}

#pragma mark - Banner

- (void)getBannerWithSize:(GADAdSize)adSize {
  NSError *error =
      [NSError errorWithDomain:kGADMAdapterAdColonyErrorDomain
                          code:kGADErrorInvalidRequest
                      userInfo:@{
                        NSLocalizedDescriptionKey : @"AdColony adapter doesn't currently support"
                                                     "Instant-Feed videos."
                      }];
  [self.connector adapter:self didFailAd:error];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return NO;
}

#pragma mark - Misc

- (void)stopBeingDelegate {
  // AdColony retains the AdColonyAdDelegate during ad playback and does not issue any callbacks
  // outside of ad playback or async calls already in flight.
  // We could cancel the callbacks for async calls already made, but is overkill IMO.
}

@end
