#import "GADMAdapterVungleRewardedAd.h"
#import "VungleRouter.h"

@interface GADMAdapterVungleRewardedAd () <VungleDelegate>

@property(nonatomic, strong) GADMediationRewardedAdConfiguration *adConfiguration;
@property(nonatomic, copy) GADRewardedLoadCompletionHandler adLoadCompletionHandler;
@property(nonatomic, weak, nullable) id<GADMediationRewardedAdEventDelegate> delegate;

@end

@implementation GADMAdapterVungleRewardedAd

// To check if the ad is presenting so that we don't call 'adLoadCompletionHandler' twice.
BOOL _isAdInUse;

- (instancetype)initWithAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                      completionHandler:(GADRewardedLoadCompletionHandler)handler {
  self = [super init];
  if (self) {
    self.adConfiguration = adConfiguration;
    self.adLoadCompletionHandler = handler;
  }
  return self;
}

- (void)requestRewardedAd {

  desiredPlacement = [VungleRouter findPlacement:[[self.adConfiguration credentials] settings]
                                   networkExtras:[self.adConfiguration extras]];
  if (!desiredPlacement) {
    NSError *error =
        [NSError errorWithDomain:@"GADMAdapterVungleRewardedAd"
                            code:0
                        userInfo:@{NSLocalizedDescriptionKey : @"'placementID' not specified"}];
    self.adLoadCompletionHandler(nil, error);
    self.adLoadCompletionHandler = nil;
    return;
  }

  NSArray *delegates = [[VungleRouter sharedInstance] getDelegates];

  for (id<VungleDelegate> value in delegates) {
    if ([[value desiredPlacement] isEqualToString:desiredPlacement]) {
      NSError *error = [NSError
        errorWithDomain:@"GADMAdapterVungleRewardedAd"
                  code:0
              userInfo:@{
                NSLocalizedDescriptionKey : @"Can't request ad if another request is in processing."
              }];
      self.adLoadCompletionHandler(nil, error);
      self.adLoadCompletionHandler = nil;
      return;
    }
  }
  GADMAdapterVungleRewardedAd __weak *weakSelf = self;
  [[VungleRouter sharedInstance] addDelegate:weakSelf];

  VungleSDK *sdk = [VungleSDK sharedSDK];
  __block NSDictionary *userInfo;

  if (![sdk isInitialized]) {
    [VungleRouter parseServerParameters:[[self.adConfiguration credentials] settings]
                          networkExtras:[self.adConfiguration extras]
                                 result:^void(NSDictionary *error, NSString *appId) {
                                   if (error) {
                                     userInfo = [[NSDictionary alloc] initWithDictionary:error];
                                     return;
                                   }
                                   [[VungleRouter sharedInstance] initWithAppId:appId delegate:self];
                                 }];
  }

  if (userInfo) {
    NSError *adapterError = [NSError errorWithDomain:@"GADMAdapterVungleRewardedAd"
                                                code:0
                                            userInfo:userInfo];
    self.adLoadCompletionHandler(nil, adapterError);
    self.adLoadCompletionHandler = nil;
    return;
  }

  if ([sdk isAdCachedForPlacementID:desiredPlacement]) {
    self.delegate = self.adLoadCompletionHandler(self, nil);
    self.adLoadCompletionHandler = nil;
  } else {
    [[VungleRouter sharedInstance] loadAd:desiredPlacement];
  }
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  _isAdInUse = YES;
  if (![[VungleRouter sharedInstance] playAd:viewController
                                    delegate:self
                                      extras:[self.adConfiguration extras]]) {
    NSError *error = [NSError
        errorWithDomain:@"GADMAdapterVungleRewardedAd"
                   code:0
               userInfo:@{
                 NSLocalizedDescriptionKey : @"Adapter failed to present rewarded ad"
               }];
    self.adLoadCompletionHandler(nil, error);
    self.adLoadCompletionHandler = nil;
  }
}

- (void)dealloc {
  self.adLoadCompletionHandler = nil;
  self.adConfiguration = nil;
  [[VungleRouter sharedInstance] removeDelegate:self];
}

#pragma mark - VungleRouter delegates

@synthesize desiredPlacement;

- (void)initialized:(BOOL)isSuccess error:(NSError *)error {
  if (!isSuccess) {
    self.adLoadCompletionHandler(nil, error);
    self.adLoadCompletionHandler = nil;
  }
}

- (void)adAvailable {
  if (!_isAdInUse) {
    self.delegate = self.adLoadCompletionHandler(self, nil);
    self.adLoadCompletionHandler = nil;
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
  _isAdInUse = NO;
  GADMAdapterVungleRewardedAd __weak *weakSelf = self;
  [[VungleRouter sharedInstance] removeDelegate:weakSelf];
  [self.delegate willDismissFullScreenView];
}

- (void)willShowAd {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = self.delegate;
  [strongDelegate willPresentFullScreenView];
  [strongDelegate reportImpression];
  [strongDelegate didStartVideo];
}

@end
