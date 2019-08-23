
#import "GADMAdapterMoPubSingleton.h"
#import "GADMAdapterMoPubUtils.h"
#import "MPRewardedVideo.h"

@interface GADMAdapterMoPubSingleton () <MPRewardedVideoDelegate>
@end

@implementation GADMAdapterMoPubSingleton {
  NSMapTable<NSString *, id<MPRewardedVideoDelegate>> *_adapterDelegates;
}

+ (nonnull instancetype)sharedInstance {
  static GADMAdapterMoPubSingleton *sharedMyManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedMyManager = [[self alloc] init];
  });
  return sharedMyManager;
}

- (nonnull instancetype)init {
  if (self = [super init]) {
    _adapterDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                  valueOptions:NSPointerFunctionsWeakMemory];
  }
  return self;
}

- (void)initializeMoPubSDKWithAdUnitID:(nonnull NSString *)adUnitID
                     completionHandler:(void (^_Nullable)(void))completionHandler {
  if (MoPub.sharedInstance.isSdkInitialized) {
    completionHandler();
    return;
  }

  MPMoPubConfiguration *sdkConfig =
      [[MPMoPubConfiguration alloc] initWithAdUnitIdForAppInitialization:adUnitID];

  [MoPub.sharedInstance initializeSdkWithConfiguration:sdkConfig
                                            completion:^{
                                              NSLog(@"MoPub SDK initialized.");
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                completionHandler();
                                              });
                                            }];
}

- (void)addDelegate:(id<MPRewardedVideoDelegate>)adapterDelegate forAdUnitID:(NSString *)adUnitID {
  @synchronized(_adapterDelegates) {
    GADMAdapterMoPubMapTableSetObjectForKey(_adapterDelegates, adUnitID, adapterDelegate);
  }
}

- (void)removeDelegateForAdUnitID:(NSString *)adUnitID {
  @synchronized(_adapterDelegates) {
    GADMAdapterMoPubMapTableRemoveObjectForKey(_adapterDelegates, adUnitID);
  }
}

- (id<MPRewardedVideoDelegate>)getDelegateForAdUnitID:(NSString *)adUnitID {
  @synchronized(_adapterDelegates) {
    return [_adapterDelegates objectForKey:adUnitID];
  }
}

- (nullable NSError *)requestRewardedAdForAdUnitID:(nonnull NSString *)adUnitID
                                 adConfig:(nonnull GADMediationRewardedAdConfiguration *)adConfig
                                 delegate:(nonnull id<MPRewardedVideoDelegate>)delegate {
  [MPRewardedVideo setDelegate:self forAdUnitId:adUnitID];

  if ([self getDelegateForAdUnitID:adUnitID]) {
    NSString *description = @"MoPub does not support requesting a 2nd ad for the same ad unit ID "
                            @"while the first request is in progress.";
    NSDictionary *userInfo =
        @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};

    NSError *error = [NSError errorWithDomain:kGADMAdapterMoPubErrorDomain
                                         code:0
                                     userInfo:userInfo];
    return error;
  } else {
    [self addDelegate:delegate forAdUnitID:adUnitID];
  }

  CLLocation *currentlocation = [[CLLocation alloc] initWithLatitude:adConfig.userLatitude
                                                           longitude:adConfig.userLongitude];

  [MPRewardedVideo loadRewardedVideoAdWithAdUnitID:adUnitID
                                          keywords:[self getKeywords:false forAdConfig:adConfig]
                                  userDataKeywords:[self getKeywords:true forAdConfig:adConfig]
                                          location:currentlocation
                                 mediationSettings:@[]];
  return nil;
}

/// Keywords passed from AdMob are separated into 1) personally identifiable,
/// and 2) non-personally identifiable categories before they are forwarded to MoPub due to GDPR.
- (NSString *)getKeywords:(BOOL)intendedForPII
              forAdConfig:(nonnull GADMediationRewardedAdConfiguration *)adConfig {
  NSString *keywordsBuilder = [NSString stringWithFormat:@"%@", kGADMAdapterMoPubTpValue];

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

#pragma mark MPRewardedVideoDelegate methods

- (void)rewardedVideoAdDidLoadForAdUnitID:(NSString *)adUnitID {
  id<MPRewardedVideoDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if (delegate) {
    [delegate rewardedVideoAdDidLoadForAdUnitID:adUnitID];
  }
}

- (void)rewardedVideoAdDidFailToLoadForAdUnitID:(NSString *)adUnitID error:(NSError *)error {
  id<MPRewardedVideoDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if (delegate) {
    [self removeDelegateForAdUnitID:adUnitID];
    [delegate rewardedVideoAdDidFailToLoadForAdUnitID:adUnitID error:error];
  }
}

- (void)rewardedVideoAdWillAppearForAdUnitID:(NSString *)adUnitID {
  id<MPRewardedVideoDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if (delegate) {
    [delegate rewardedVideoAdWillAppearForAdUnitID:adUnitID];
  }
}

- (void)rewardedVideoAdDidAppearForAdUnitID:(NSString *)adUnitID {
  id<MPRewardedVideoDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if (delegate) {
    [delegate rewardedVideoAdDidAppearForAdUnitID:adUnitID];
  }
}

- (void)rewardedVideoAdWillDisappearForAdUnitID:(NSString *)adUnitID {
  id<MPRewardedVideoDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if (delegate) {
    [delegate rewardedVideoAdWillDisappearForAdUnitID:adUnitID];
  }
}

- (void)rewardedVideoAdDidDisappearForAdUnitID:(NSString *)adUnitID {
  id<MPRewardedVideoDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if (delegate) {
    [self removeDelegateForAdUnitID:adUnitID];
    [delegate rewardedVideoAdDidDisappearForAdUnitID:adUnitID];
  }
}

- (void)rewardedVideoAdDidExpireForAdUnitID:(NSString *)adUnitID {
  id<MPRewardedVideoDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if (delegate) {
    [self removeDelegateForAdUnitID:adUnitID];
    [delegate rewardedVideoAdDidExpireForAdUnitID:adUnitID];
  }
}

- (void)rewardedVideoAdDidReceiveTapEventForAdUnitID:(NSString *)adUnitID {
  id<MPRewardedVideoDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if (delegate) {
    [delegate rewardedVideoAdDidReceiveTapEventForAdUnitID:adUnitID];
  }
}

- (void)rewardedVideoWillLeaveApplicationForAdUnitID:(NSString *)adUnitID {
  id<MPRewardedVideoDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if (delegate) {
    [delegate rewardedVideoAdWillLeaveApplicationForAdUnitID:adUnitID];
  }
}

- (void)rewardedVideoAdShouldRewardForAdUnitID:(NSString *)adUnitID
                                        reward:(MPRewardedVideoReward *)reward {
  id<MPRewardedVideoDelegate> delegate = [self getDelegateForAdUnitID:adUnitID];
  if (delegate) {
    [delegate rewardedVideoAdShouldRewardForAdUnitID:adUnitID reward:reward];
  }
}

@end
