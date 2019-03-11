#import "GADMediationAdapterMoPub.h"

#import "GADMoPubNetworkExtras.h"
#import "MPRewardedVideo.h"
#import "MoPub.h"
#import "MoPubAdapterConstants.h"

@interface GADMediationAdapterMoPub () <MPRewardedVideoDelegate>

/// Connector from Google Mobile Ads SDK to receive ad configurations.
@property(nonatomic, weak) id<GADMRewardBasedVideoAdNetworkConnector> rewardedConnector;
@property(nonatomic, strong) NSString *rewardedAdUnitId;
@property(nonatomic, assign) BOOL adExpired;

@end

@implementation GADMediationAdapterMoPub

+ (NSString *)adapterVersion {
  return GADMAdapterMoPubVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMoPubNetworkExtras class];
}

- (void)initializeMoPub:(NSString *)adUnitId {
  MPMoPubConfiguration *sdkConfig =
      [[MPMoPubConfiguration alloc] initWithAdUnitIdForAppInitialization:adUnitId];

  if (!MoPub.sharedInstance.isSdkInitialized) {
    [[MoPub sharedInstance] initializeSdkWithConfiguration:sdkConfig
                                                completion:^{
                                                  NSLog(@"MoPub SDK initialized.");
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                    // No need to request ad at this point. It'll be
                                                    // done when AdMob calls
                                                    // requestRewardBasedVideoAd
                                                    [MPRewardedVideo
                                                        setDelegate:self
                                                        forAdUnitId:self.rewardedAdUnitId];
                                                  });
                                                }];
  }
}

- (void)stopBeingDelegate {
  [MPRewardedVideo removeDelegateForAdUnitId:self.rewardedAdUnitId];
}
/*
 Keywords passed from AdMob are separated into 1) personally identifiable,
 and 2) non-personally identifiable categories before they are forwarded to MoPub due to GDPR.
 */
- (NSString *)getKeywords:(BOOL)intendedForPII {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardedConnector;
  NSDate *birthday = [strongConnector userBirthday];
  NSString *ageString = @"";

  if (birthday) {
    NSInteger ageInteger = [self ageFromBirthday:birthday];
    ageString = [@"m_age:" stringByAppendingString:[@(ageInteger) stringValue]];
  }

  GADGender gender = [strongConnector userGender];
  NSString *genderString = @"";

  if (gender == kGADGenderMale) {
    genderString = @"m_gender:m";
  } else if (gender == kGADGenderFemale) {
    genderString = @"m_gender:f";
  }
  NSString *keywordsBuilder =
      [NSString stringWithFormat:@"%@,%@,%@", kAdapterTpValue, ageString, genderString];

  if (intendedForPII) {
    if ([[MoPub sharedInstance] canCollectPersonalInfo]) {
      return [self keywordsContainUserData:strongConnector] ? keywordsBuilder : @"";
    } else {
      return @"";
    }
  } else {
    return [self keywordsContainUserData:strongConnector] ? @"" : keywordsBuilder;
  }
}

- (NSInteger)ageFromBirthday:(NSDate *)birthdate {
  NSDate *today = [NSDate date];
  NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear
                                                                    fromDate:birthdate
                                                                      toDate:today
                                                                     options:0];
  return ageComponents.year;
}

- (BOOL)keywordsContainUserData:(id<GADMRewardBasedVideoAdNetworkConnector>)rewardedConnector {
  return [rewardedConnector userGender] || [rewardedConnector userBirthday] ||
         [rewardedConnector userHasLocation];
}

#pragma mark - Rewarded Video

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:(id)connector {
  if (!connector) {
    return nil;
  }
  self = [super init];
  if (self) {
    _adExpired = false;
    _rewardedConnector = connector;
    _rewardedAdUnitId = [self.rewardedConnector.credentials objectForKey:@"pubid"];
    if (![[MoPub sharedInstance] isSdkInitialized]) {
      [self initializeMoPub:_rewardedAdUnitId];
    }
  }
  return self;
}

- (void)setUp {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardedConnector;
  if ([_rewardedAdUnitId length] == 0) {
    NSString *description = @"Failed to request a MoPub rewarded ad. Ad unit ID is empty.";
    NSDictionary *userInfo =
        @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};

    NSError *error = [NSError errorWithDomain:kAdapterErrorDomain code:0 userInfo:userInfo];
    [strongConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
  }
  [MPRewardedVideo setDelegate:self forAdUnitId:self.rewardedAdUnitId];
  [strongConnector adapterDidSetUpRewardBasedVideoAd:self];
}

- (void)requestRewardBasedVideoAd {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardedConnector;
  CLLocation *currentlocation = [[CLLocation alloc] initWithLatitude:strongConnector.userLatitude
                                                           longitude:strongConnector.userLongitude];

  if ([self.rewardedAdUnitId length] != 0 &&
      [MPRewardedVideo hasAdAvailableForAdUnitID:self.rewardedAdUnitId]) {
    [strongConnector adapterDidReceiveRewardBasedVideoAd:self];
  } else {
    [MPRewardedVideo loadRewardedVideoAdWithAdUnitID:_rewardedAdUnitId
                                            keywords:[self getKeywords:false]
                                    userDataKeywords:[self getKeywords:true]
                                            location:currentlocation
                                   mediationSettings:@[]];
  }
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
  // MoPub ads have a 4-hour expiration time window
  if (!_adExpired && [self.rewardedAdUnitId length] != 0 &&
      [MPRewardedVideo hasAdAvailableForAdUnitID:self.rewardedAdUnitId]) {
    NSArray *rewards = [MPRewardedVideo availableRewardsForAdUnitID:self.rewardedAdUnitId];
    MPRewardedVideoReward *reward = rewards[0];

    [MPRewardedVideo presentRewardedVideoAdForAdUnitID:self.rewardedAdUnitId
                                    fromViewController:viewController
                                            withReward:reward];
  } else {
    NSString *description = @"Failed to show a MoPub rewarded ad. No ad available.";
    NSDictionary *userInfo =
        @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};

    NSError *error = [NSError errorWithDomain:kAdapterErrorDomain code:0 userInfo:userInfo];
    [_rewardedConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:error];
  }
}

#pragma mark SampleRewardBasedVideoDelegate methods

- (void)rewardedVideoAdDidLoadForAdUnitID:(NSString *)adUnitID {
  id strongAdapter = self;
  [_rewardedConnector adapterDidReceiveRewardBasedVideoAd:strongAdapter];
}

- (void)rewardedVideoAdDidFailToLoadForAdUnitID:(NSString *)adUnitID error:(NSError *)error {
  id strongAdapter = self;
  [_rewardedConnector adapter:strongAdapter didFailToLoadRewardBasedVideoAdwithError:error];
}

- (void)rewardedVideoAdWillAppearForAdUnitID:(NSString *)adUnitID {
}

- (void)rewardedVideoAdDidAppearForAdUnitID:(NSString *)adUnitID {
  id strongAdapter = self;
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardedConnector;
  [strongConnector adapterDidStartPlayingRewardBasedVideoAd:strongAdapter];
  [strongConnector adapterDidOpenRewardBasedVideoAd:strongAdapter];
}

- (void)rewardedVideoAdWillDisappearForAdUnitID:(NSString *)adUnitID {
}

- (void)rewardedVideoAdDidDisappearForAdUnitID:(NSString *)adUnitID {
  id strongAdapter = self;
  [_rewardedConnector adapterDidCloseRewardBasedVideoAd:strongAdapter];
}

- (void)rewardedVideoAdDidExpireForAdUnitID:(NSString *)adUnitID {
  _adExpired = true;
  id strongAdapter = self;

  NSString *description = @"Failed to show a MoPub rewarded ad. Ad has expired after 4 hours. "
                          @"Please make a new ad request.";
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};

  NSError *error = [NSError errorWithDomain:kAdapterErrorDomain code:0 userInfo:userInfo];
  [_rewardedConnector adapter:strongAdapter didFailToLoadRewardBasedVideoAdwithError:error];
}

- (void)rewardedVideoAdDidReceiveTapEventForAdUnitID:(NSString *)adUnitID {
  id strongAdapter = self;
  [_rewardedConnector adapterDidGetAdClick:strongAdapter];
}

- (void)rewardedVideoWillLeaveApplicationForAdUnitID:(NSString *)adUnitID {
  id strongAdapter = self;
  [_rewardedConnector adapterWillLeaveApplication:strongAdapter];
}

- (void)rewardedVideoAdShouldRewardForAdUnitID:(NSString *)adUnitID
                                        reward:(MPRewardedVideoReward *)reward {
  id strongAdapter = self;
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardedConnector;
  NSDecimalNumber *rewardAmount =
      [NSDecimalNumber decimalNumberWithDecimal:[reward.amount decimalValue]];
  NSString *rewardType = reward.currencyType;

  GADAdReward *rewardItem = [[GADAdReward alloc] initWithRewardType:rewardType
                                                       rewardAmount:rewardAmount];

  [strongConnector adapterDidCompletePlayingRewardBasedVideoAd:strongAdapter];
  [strongConnector adapter:strongAdapter didRewardUserWithReward:rewardItem];
}

@end
