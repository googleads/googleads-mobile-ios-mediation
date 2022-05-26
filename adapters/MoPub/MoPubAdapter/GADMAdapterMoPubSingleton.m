#import "GADMAdapterMoPubSingleton.h"

#import "GADMAdapterMoPubUtils.h"

@interface GADMAdapterMoPubSingleton () <MPRewardedAdsDelegate>
@end

@implementation GADMAdapterMoPubSingleton {
  /// Stores rewarded ad delegate with ad unit identifier as a key.
  NSMapTable<NSString *, id<MPRewardedAdsDelegate>> *_adapterDelegates;

  /// Serializes ivar usage.
  dispatch_queue_t _lockQueue;
}

+ (nonnull GADMAdapterMoPubSingleton *)sharedInstance {
  static GADMAdapterMoPubSingleton *sharedMyManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedMyManager = [[self alloc] init];
  });
  return sharedMyManager;
}

- (nonnull instancetype)init {
  self = [super init];
  if (self) {
    _adapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                              valueOptions:NSPointerFunctionsWeakMemory];
    _lockQueue = dispatch_queue_create("mopub-rewardedAdapterDelegates", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void)initializeMoPubSDKWithAdUnitID:(nonnull NSString *)adUnitID
                     completionHandler:(void (^_Nullable)(void))completionHandler {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (MoPub.sharedInstance.isSdkInitialized) {
      completionHandler();
      return;
    }

    MPMoPubConfiguration *sdkConfig =
        [[MPMoPubConfiguration alloc] initWithAdUnitIdForAppInitialization:adUnitID];

    [MoPub.sharedInstance
        initializeSdkWithConfiguration:sdkConfig
                            completion:^{
                              NSLog(@"MoPub SDK initialized.");
                              dispatch_async(dispatch_get_main_queue(), completionHandler);
                            }];
  });
}

- (void)addDelegate:(nonnull id<MPRewardedAdsDelegate>)adapterDelegate
        forAdUnitID:(nonnull NSString *)adUnitID {
  dispatch_async(_lockQueue, ^{
    GADMAdapterMoPubMapTableSetObjectForKey(self->_adapterDelegates, adUnitID, adapterDelegate);
  });
}

- (void)removeDelegateForAdUnitID:(nonnull NSString *)adUnitID {
  dispatch_async(_lockQueue, ^{
    GADMAdapterMoPubMapTableRemoveObjectForKey(self->_adapterDelegates, adUnitID);
  });
}

- (nullable id<MPRewardedAdsDelegate>)getDelegateForAdUnitID:(nonnull NSString *)adUnitID {
  __block id<MPRewardedAdsDelegate> delegate = nil;
  dispatch_sync(_lockQueue, ^{
    delegate = [self->_adapterDelegates objectForKey:adUnitID];
  });
  return delegate;
}

- (nullable NSError *)
    requestRewardedAdForAdUnitID:(nonnull NSString *)adUnitID
                        adConfig:(nonnull GADMediationRewardedAdConfiguration *)adConfig
                        delegate:(nonnull id<MPRewardedAdsDelegate>)delegate {
  [MPRewardedAds setDelegate:self forAdUnitId:adUnitID];

  if ([self getDelegateForAdUnitID:adUnitID]) {
    NSError *error = GADMoPubErrorWithCodeAndDescription(
        GADMoPubErrorAdAlreadyLoaded, @"MoPub does not support requesting a 2nd ad for the same ad "
                                      @"unit ID while the first request is in progress.");
    return error;
  } else {
    [self addDelegate:delegate forAdUnitID:adUnitID];
  }

  [MPRewardedAds loadRewardedAdWithAdUnitID:adUnitID
                                   keywords:[self getKeywords:false forAdConfig:adConfig]
                           userDataKeywords:[self getKeywords:true forAdConfig:adConfig]
                          mediationSettings:@[]];
  return nil;
}

/// Keywords passed from AdMob are separated into 1) personally identifiable,
/// and 2) non-personally identifiable categories before they are forwarded to MoPub due to GDPR.
- (NSString *)getKeywords:(BOOL)intendedForPII
              forAdConfig:(nonnull GADMediationRewardedAdConfiguration *)adConfig {
  NSString *keywordsBuilder = [NSString stringWithFormat:@"%@", GADMAdapterMoPubTpValue];

  if (intendedForPII) {
    if ([[MoPub sharedInstance] canCollectPersonalInfo]) {
      return [self keywordsContainUserData:adConfig] ? keywordsBuilder : @"";
    } else {
      return @"";
    }
  } else {
    return [self keywordsContainUserData:adConfig] ? @"" : keywordsBuilder;
  }
}

- (BOOL)keywordsContainUserData:(nonnull GADMediationRewardedAdConfiguration *)adConfig {
  return [adConfig hasUserLocation];
}

#pragma mark MPRewardedAdsDelegate methods

- (void)rewardedAdDidLoadForAdUnitID:(NSString *)adUnitID {
  id<MPRewardedAdsDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if ([delegate respondsToSelector:@selector(rewardedAdDidLoadForAdUnitID:)]) {
    [delegate rewardedAdDidLoadForAdUnitID:adUnitID];
  }
}

- (void)rewardedAdDidFailToLoadForAdUnitID:(NSString *)adUnitID error:(NSError *)error {
  id<MPRewardedAdsDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if ([delegate respondsToSelector:@selector(rewardedAdDidFailToLoadForAdUnitID:error:)]) {
    [self removeDelegateForAdUnitID:adUnitID];
    [delegate rewardedAdDidFailToLoadForAdUnitID:adUnitID error:error];
  }
}

- (void)rewardedAdWillPresentForAdUnitID:(NSString *)adUnitID {
  id<MPRewardedAdsDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if ([delegate respondsToSelector:@selector(rewardedAdWillPresentForAdUnitID:)]) {
    [delegate rewardedAdWillPresentForAdUnitID:adUnitID];
  }
}

- (void)rewardedAdDidPresentForAdUnitID:(NSString *)adUnitID {
  id<MPRewardedAdsDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if ([delegate respondsToSelector:@selector(rewardedAdDidPresentForAdUnitID:)]) {
    [delegate rewardedAdDidPresentForAdUnitID:adUnitID];
  }
}

- (void)rewardedAdWillDismissForAdUnitID:(NSString *)adUnitID {
  id<MPRewardedAdsDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if ([delegate respondsToSelector:@selector(rewardedAdWillDismissForAdUnitID:)]) {
    [delegate rewardedAdWillDismissForAdUnitID:adUnitID];
  }
}

- (void)rewardedAdDidDismissForAdUnitID:(NSString *)adUnitID {
  id<MPRewardedAdsDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if ([delegate respondsToSelector:@selector(rewardedAdDidDismissForAdUnitID:)]) {
    [self removeDelegateForAdUnitID:adUnitID];
    [delegate rewardedAdDidDismissForAdUnitID:adUnitID];
  }
}

- (void)rewardedAdDidExpireForAdUnitID:(NSString *)adUnitID {
  id<MPRewardedAdsDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if ([delegate respondsToSelector:@selector(rewardedAdDidExpireForAdUnitID:)]) {
    [self removeDelegateForAdUnitID:adUnitID];
    [delegate rewardedAdDidExpireForAdUnitID:adUnitID];
  }
}

- (void)rewardedAdDidReceiveTapEventForAdUnitID:(NSString *)adUnitID {
  id<MPRewardedAdsDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if ([delegate respondsToSelector:@selector(rewardedAdDidReceiveTapEventForAdUnitID:)]) {
    [delegate rewardedAdDidReceiveTapEventForAdUnitID:adUnitID];
  }
}

- (void)rewardedAdWillLeaveApplicationForAdUnitID:(NSString *)adUnitID {
  id<MPRewardedAdsDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if ([delegate respondsToSelector:@selector(rewardedAdWillLeaveApplicationForAdUnitID:)]) {
    [delegate rewardedAdWillLeaveApplicationForAdUnitID:adUnitID];
  }
}

- (void)rewardedAdShouldRewardForAdUnitID:(NSString *)adUnitID reward:(MPReward *)reward {
  id<MPRewardedAdsDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if ([delegate respondsToSelector:@selector(rewardedAdShouldRewardForAdUnitID:reward:)]) {
    [delegate rewardedAdShouldRewardForAdUnitID:adUnitID reward:reward];
  }
}

@end
