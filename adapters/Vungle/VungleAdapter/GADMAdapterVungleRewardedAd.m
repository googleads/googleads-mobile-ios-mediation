#import "GADMAdapterVungleRewardedAd.h"
#include <stdatomic.h>
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleUtils.h"
#import "VungleRouter.h"

@interface GADMAdapterVungleRewardedAd () <VungleDelegate, VungleSDKDelegate>

@property(nonatomic, strong) GADMediationRewardedAdConfiguration *adConfiguration;
@property(nonatomic, copy) GADMediationRewardedLoadCompletionHandler adLoadCompletionHandler;
@property(nonatomic, weak, nullable) id<GADMediationRewardedAdEventDelegate> delegate;

@end

@implementation GADMAdapterVungleRewardedAd

// To check if the ad is presenting so that we don't call 'adLoadCompletionHandler' twice.
BOOL _isRewardedAdPresenting;

- (instancetype)initWithAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                      completionHandler:(GADMediationRewardedLoadCompletionHandler)handler {
  self = [super init];
  if (self) {
    self.adConfiguration = adConfiguration;

    __block atomic_flag adLoadHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationRewardedLoadCompletionHandler origAdLoadHandler = [handler copy];

    // Ensure the original completion handler is only called once, and is deallocated once called.
    self.adLoadCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
        id<GADMediationRewardedAd> rewardedAd, NSError *error) {
      if (atomic_flag_test_and_set(&adLoadHandlerCalled)) {
        return nil;
      }

      id<GADMediationRewardedAdEventDelegate> delegate = nil;
      if (origAdLoadHandler) {
        delegate = origAdLoadHandler(rewardedAd, error);
      }

      origAdLoadHandler = nil;
      return delegate;
    };
  }
  return self;
}

- (void)requestRewardedAd {
  desiredPlacement = [GADMAdapterVungleUtils findPlacement:self.adConfiguration.credentials.settings
                                             networkExtras:self.adConfiguration.extras];
  if (!desiredPlacement) {
    NSError *error =
        [NSError errorWithDomain:kGADMAdapterVungleErrorDomain
                            code:0
                        userInfo:@{NSLocalizedDescriptionKey : @"'placementID' not specified"}];
    self.adLoadCompletionHandler(nil, error);
    return;
  }

  VungleSDK *sdk = [VungleSDK sharedSDK];

  if (![sdk isInitialized]) {
    NSString *appID = [GADMAdapterVungleUtils findAppID:self.adConfiguration.credentials.settings];
    if (appID) {
      [[VungleRouter sharedInstance] initWithAppId:appID delegate:self];
    } else {
      NSError *error = [NSError
          errorWithDomain:kGADMAdapterVungleErrorDomain
                     code:0
                 userInfo:@{NSLocalizedDescriptionKey : @"Vungle app ID should be specified!"}];
      self.adLoadCompletionHandler(nil, error);
    }
  } else {
    [self loadRewardedAd];
  }
}

- (void)loadRewardedAd {
  NSError *error = [[VungleRouter sharedInstance] loadAd:desiredPlacement withDelegate:self];
  if (error) {
    self.adLoadCompletionHandler(nil, error);
  }
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  _isRewardedAdPresenting = YES;
  if (![[VungleRouter sharedInstance] playAd:viewController
                                    delegate:self
                                      extras:[self.adConfiguration extras]]) {
    NSError *error = [NSError
        errorWithDomain:kGADMAdapterVungleErrorDomain
                   code:0
               userInfo:@{NSLocalizedDescriptionKey : @"Adapter failed to present rewarded ad"}];
    self.adLoadCompletionHandler(nil, error);
    self.adLoadCompletionHandler = nil;
  }
}

#pragma mark - VungleRouter delegates

@synthesize desiredPlacement;

- (void)initialized:(BOOL)isSuccess error:(NSError *)error {
  if (isSuccess) {
    [self loadRewardedAd];
  } else {
    self.adLoadCompletionHandler(nil, error);
  }
}

- (void)adAvailable {
  if (!_isRewardedAdPresenting) {
    self.delegate = self.adLoadCompletionHandler(self, nil);
  }
}

- (void)didCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = self.delegate;
  if (completedView) {
    [strongDelegate didEndVideo];
    GADAdReward *reward =
        [[GADAdReward alloc] initWithRewardType:@"vungle"
                                   rewardAmount:[NSDecimalNumber decimalNumberWithString:@"1"]];
    [strongDelegate didRewardUserWithReward:reward];
  }
  if (didDownload) {
    [strongDelegate reportClick];
  }
  desiredPlacement = nil;
  [strongDelegate didDismissFullScreenView];
}

- (void)willCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload {
  _isRewardedAdPresenting = NO;
  [self.delegate willDismissFullScreenView];
}

- (void)willShowAd {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = self.delegate;
  [strongDelegate willPresentFullScreenView];
  [strongDelegate reportImpression];
  [strongDelegate didStartVideo];
}

- (void)adNotAvailable:(NSError *)error {
  self.adLoadCompletionHandler(nil, error);
}

@end
