//
// Copyright 2016, AdColony, Inc.
//

#import "GADMAdapterAdColony.h"
#import "GADMAdapterAdColonyExtras.h"

#import <AdColony/AdColony.h>

#define DEBUG_LOGGING 0

#if DEBUG_LOGGING
#define NSLogDebug(...) NSLog(__VA_ARGS__)
#else
#define NSLogDebug(...)
#endif

typedef enum {
  INIT_STATE_UNINITIALIZED,
  INIT_STATE_INITIALIZED,
  INIT_STATE_INITIALIZING
} InitState;

@interface AdColonyInitializer : NSObject

@property NSSet *zones;
@property InitState initState;
@property NSArray *callbacks;

+ (AdColonyInitializer *)sharedInstance;

@end

@implementation AdColonyInitializer

+ (AdColonyInitializer *)sharedInstance {
  static dispatch_once_t onceToken;
  static AdColonyInitializer *instance;
  dispatch_once(&onceToken, ^{
    instance = [[AdColonyInitializer alloc] init];
  });
  return instance;
}

- (id)init {
  if (self = [super init]) {
    _zones = [NSSet set];
    _callbacks = [NSArray array];
  }
  return self;
}

- (void)initializeAdColonyWithAppId:(NSString *)appId
                              zones:(NSArray *)newZones
                            request:(id<GADMediationAdRequest>)request
                           callback:(void (^)())callback {
  @synchronized(self) {
    NSLogDebug(@"new zones: %@", newZones);
    NSLogDebug(@"old zones: %@", self.zones);

    // Even if ADC configure should be smart with configuring with superset/subset of zones, manage
    // it here too.
    NSSet *oldZones = [NSSet setWithSet:self.zones];
    self.zones = [self.zones setByAddingObjectsFromArray:newZones];
    if (![oldZones isEqualToSet:self.zones]) {
      self.initState = INIT_STATE_UNINITIALIZED;
    }

    // If ADC options have already been set, used directly or from previous configure here, use it
    // Only build new options if not previously set.
    AdColonyAppOptions *options = [self getAppOptionsFromRequest:request];
    if (options && self.initState == INIT_STATE_INITIALIZED) {
      [AdColony setAppOptions:options];
    }

    if (self.initState == INIT_STATE_INITIALIZED) {
      if (callback) {
        callback();
      }
    } else {
      if (callback) {
        self.callbacks = [self.callbacks arrayByAddingObject:callback];
      }

      // Don't allow multiple config requests, the 2nd will use the results of the previous.
      if (self.initState != INIT_STATE_INITIALIZING) {
        self.initState = INIT_STATE_INITIALIZING;
        __weak AdColonyInitializer *weakSelf = self;
        NSLogDebug(@"zones: %@", [self.zones allObjects]);
        [AdColony configureWithAppID:appId
                             zoneIDs:[self.zones allObjects]
                             options:options
                          completion:^(NSArray<AdColonyZone *> *_Nonnull zones) {
                            NSLogDebug(@"config callback");
                            @synchronized(weakSelf) {
                              weakSelf.initState = INIT_STATE_INITIALIZED;
                              for (void (^localCallback)() in weakSelf.callbacks) {
                                localCallback();
                              }
                              weakSelf.callbacks = [NSArray array];
                            }
                          }];
      } else {
        // Not important enough to spam a warning. It's going to happen every time, no doubt.
        // NSLog(@"AdColonyAdapter [*Warning*] : configuration called while another in flight, 2nd"
        // "call ignored.");
      }
    }
  }
}

- (AdColonyAppOptions *)getAppOptionsFromRequest:(id<GADMediationAdRequest>)request {
  AdColonyAppOptions *options = [AdColonyAppOptions new];
  options.userMetadata = [AdColonyUserMetadata new];

  GADMAdapterAdColonyExtras *extras = request.networkExtras;
  if (extras && [extras isKindOfClass:[GADMAdapterAdColonyExtras class]]) {
    options.userID = extras.userId;
    options.testMode = extras.testMode;
    if (extras.gdprRequired) {
      options.gdprRequired = extras.gdprRequired;
      options.gdprConsentString = extras.gdprConsentString;
    }
  }

  GADGender gender = [request userGender];
  if (gender == kGADGenderMale) {
    options.userMetadata.userGender = ADCUserMale;
  } else if (gender == kGADGenderFemale) {
    options.userMetadata.userGender = ADCUserFemale;
  }

  NSDate *birthday = [request userBirthday];
  if (birthday) {
    options.userMetadata.userAge = [self getNumberOfYearsSinceDate:birthday];
  }

  if ([request userHasLocation]) {
    options.userMetadata.userLatitude = @([request userLatitude]);
    options.userMetadata.userLongitude = @([request userLongitude]);
  }

  [options setMediationNetwork:ADCAdMob];
  [options setMediationNetworkVersion:[GADMAdapterAdColony adapterVersion]];

  return options;
}

- (NSInteger)getNumberOfYearsSinceDate:(NSDate *)date {
  NSCalendar *calendar =
      [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  NSDateComponents *components =
      [calendar components:NSCalendarUnitYear fromDate:date toDate:[NSDate date] options:0];
  return [components year];
}

@end

@interface GADMAdapterAdColony ()

@property AdColonyInterstitial *ad;
@property NSString *appId;
@property NSString *currentZone;
@property NSArray *zones;
@property(weak) id<GADMAdNetworkConnector> connector;
@property(weak) id<GADMRewardBasedVideoAdNetworkConnector> rewardConnector;
/// this is shortcut to either connector or rewardConnector, whichever is valid.
@property(weak) id<GADMediationAdRequest> request;

@end

@implementation GADMAdapterAdColony

+ (NSString *)adapterVersion {
  return @"3.3.6.0";
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return GADMAdapterAdColonyExtras.class;
}

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:
        (id<GADMRewardBasedVideoAdNetworkConnector>)connector {
  if (self = [super init]) {
    self.rewardConnector = connector;
    self.request = connector;
    NSDictionary *credentials = [connector credentials];
    self.appId = credentials[@"app_id"];
  }
  return self;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  if (self = [super init]) {
    self.connector = connector;
    self.request = connector;
    NSDictionary *credentials = [connector credentials];
    self.appId = credentials[@"app_id"];
  }
  return self;
}

- (void)setUp {
  if (self.appId) {
    [self.rewardConnector adapterDidSetUpRewardBasedVideoAd:self];
  } else {
    NSError *error = [NSError errorWithDomain:kGADErrorDomain
                                         code:kGADErrorMediationAdapterError
                                     userInfo:@{
                                       NSLocalizedDescriptionKey : @"Adapter not initialized"
                                     }];
    [self.rewardConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
  }
}

- (NSArray *)parseZoneIDs:(NSString *)zoneList {
  // Split on the character we care about.
  NSArray *zoneIDs = [zoneList componentsSeparatedByString:@";"];
  NSMutableArray *result = [NSMutableArray arrayWithCapacity:[zoneIDs count]];

  // Trim all whitespace and add to result if not empty.
  for (NSString *zoneID in zoneIDs) {
    NSString *trimmed =
        [zoneID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![trimmed isEqualToString:@""]) {
      [result addObject:trimmed];
    }
  }
  return result;
}

- (void)setupZoneFromRequest:(id<GADMediationAdRequest>)request
                    callback:(void (^)(NSString *zone))callback {
  NSDictionary *credentials = [request credentials];

  // Support arrays for older implementations, they won't have to change their zones on the
  // dashboard.
  self.zones = [self parseZoneIDs:credentials[@"zone_ids"]];

  // Default zone is the first one in the semicolon delimited list from the AdMob Ad Unit ID.
  NSString *zone = [_zones firstObject];

  [[AdColonyInitializer sharedInstance] initializeAdColonyWithAppId:self.appId
                                                              zones:@[ zone ]
                                                            request:request
                                                           callback:^{
                                                             if (callback) {
                                                               callback(zone);
                                                             }
                                                           }];
}

- (void)getInterstitialFromZoneId:(NSString *)zone withRequest:(id<GADMediationAdRequest>)request {
  self.ad = nil;

  __weak GADMAdapterAdColony *weakSelf = self;

  AdColonyAdOptions *options = [self getAdOptionsFromRequest:request];

  NSLogDebug(@"getInterstitialFromZoneId: %@", zone);

  [AdColony requestInterstitialInZone:zone
      options:options
      success:^(AdColonyInterstitial *_Nonnull ad) {
        NSLogDebug(@"Retrieve ad: %@", zone);

        weakSelf.ad = ad;
        if (weakSelf.connector) {
          [weakSelf.connector adapterDidReceiveInterstitial:weakSelf];
        } else if (weakSelf.rewardConnector) {
          AdColonyZone *zone = [AdColony zoneForID:weakSelf.ad.zoneID];
          if (zone.rewarded) {
            [weakSelf.rewardConnector adapterDidReceiveRewardBasedVideoAd:weakSelf];
          } else {
            NSLog(@"AdColonyAdapter [**Error**] : Zone used for rewarded video is not a rewarded"
                   "video zone on AdColony portal.");
            NSError *error = [NSError
                errorWithDomain:kGADErrorDomain
                           code:kGADErrorInvalidRequest
                       userInfo:@{
                         NSLocalizedDescriptionKey : @"Zone used for rewarded video is not a"
                                                      "rewarded video zone on AdColony portal"
                       }];
            [weakSelf.rewardConnector adapter:weakSelf
                didFailToLoadRewardBasedVideoAdwithError:error];
          }
        }

        // Re-request intersitial when expires, this avoids the situation:
        // 1. Admob interstitial request from zone A. Causes ADC configure to occur with zone A,
        // then ADC ad request from zone A. Both succeed.
        // 2. Admob rewarded video request from zone B. Causes ADC configure to occur with zones A,
        // B, then ADC ad request from zone B. Both succeed.
        // 3. Try to present ad loaded from zone A. It doesn’t show because of error: `No session
        // with id: xyz has been registered. Cannot show interstitial`.
        __weak AdColonyInterstitial *weakAd = ad;
        [ad setExpire:^{
          NSLog(@"AdColonyAdapter [Info]: Ad expired from zone: %@", weakAd.zoneID);
          [weakSelf setupZoneFromRequest:request
                                callback:^(NSString *ignoredZone) {
                                  [weakSelf getInterstitialFromZoneId:zone withRequest:request];
                                }];
        }];
      }
      failure:^(AdColonyAdRequestError *_Nonnull err) {
        NSError *error =
            [NSError errorWithDomain:kGADErrorDomain
                                code:kGADErrorInvalidRequest
                            userInfo:@{NSLocalizedDescriptionKey : err.localizedDescription}];
        if (weakSelf.connector) {
          [weakSelf.connector adapter:weakSelf didFailAd:error];
        } else if (weakSelf.rewardConnector) {
          [weakSelf.rewardConnector adapter:weakSelf
              didFailToLoadRewardBasedVideoAdwithError:error];
        }
        NSLog(@"AdColonyAdapter [Info] : Failed to retrieve ad: %@", error.localizedDescription);
      }];
}

#pragma mark - Rewarded

- (void)requestRewardBasedVideoAd {
  // The only difference between Interstitials and RewardedVideo is within the interstitial and zone
  // returned from the API.
  // Rewarded videos from admob only initializes once, need to get zone from the request every time,
  // interstitials are instantiated every time.
  [self setupZoneFromRequest:self.rewardConnector
                    callback:^(NSString *zone) {
                      [self getInterstitialFromZoneId:zone withRequest:self.rewardConnector];
                    }];
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
  // The only difference between Interstitials and RewardedVideo is within the interstitial and zone
  // returned from the API.
  [self presentInterstitialFromRootViewController:viewController];
}

#pragma mark - Interstitial

- (void)getInterstitial {
  [self setupZoneFromRequest:self.connector
                    callback:^(NSString *zone) {
                      [self getInterstitialFromZoneId:zone withRequest:self.connector];
                    }];
}

- (AdColonyAdOptions *)getAdOptionsFromRequest:(id<GADMediationAdRequest>)request {
  BOOL foundOptions = FALSE;
  AdColonyAdOptions *options = [AdColonyAdOptions new];
  options.userMetadata = [AdColonyUserMetadata new];

  GADMAdapterAdColonyExtras *extras = request.networkExtras;
  if (extras && [extras isKindOfClass:[GADMAdapterAdColonyExtras class]]) {
    // Popups only apply to rewarded requests.
    if ([request conformsToProtocol:@protocol(GADMRewardBasedVideoAdNetworkConnector)]) {
      foundOptions = TRUE;
      options.showPrePopup = extras.showPrePopup;
      options.showPostPopup = extras.showPostPopup;
    }
  }

  // Don't return an empty options/metadata object if nothing was found.
  if (!foundOptions) {
    options = nil;
  }
  return options;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  __weak GADMAdapterAdColony *weakSelf = self;

  [self.ad setOpen:^{
    if (weakSelf.connector) {
      [weakSelf.connector adapterWillPresentInterstitial:weakSelf];
    } else if (weakSelf.rewardConnector) {
      [weakSelf.rewardConnector adapterDidOpenRewardBasedVideoAd:weakSelf];
      [weakSelf.rewardConnector adapterDidStartPlayingRewardBasedVideoAd:weakSelf];
    }
  }];

  [self.ad setClick:^{
    if (weakSelf.connector) {
      [weakSelf.connector adapterDidGetAdClick:weakSelf];
    } else if (weakSelf.rewardConnector) {
      [weakSelf.rewardConnector adapterDidGetAdClick:weakSelf];
    }
  }];

  [self.ad setClose:^{
    if (weakSelf.connector) {
      [weakSelf.connector adapterWillDismissInterstitial:weakSelf];
      [weakSelf.connector adapterDidDismissInterstitial:weakSelf];
    } else if (weakSelf.rewardConnector) {
      [weakSelf.rewardConnector adapterDidCloseRewardBasedVideoAd:weakSelf];
    }
  }];

  [self.ad setLeftApplication:^{
    if (weakSelf.connector) {
      [weakSelf.connector adapterWillLeaveApplication:weakSelf];
    } else if (weakSelf.rewardConnector) {
      [weakSelf.rewardConnector adapterWillLeaveApplication:weakSelf];
    }
  }];

  // Only for rewarded videos.
  if (self.rewardConnector) {
    AdColonyZone *zone = [AdColony zoneForID:self.ad.zoneID];
    [zone setReward:^(BOOL success, NSString *_Nonnull name, int amount) {
      [weakSelf.rewardConnector adapterDidCompletePlayingRewardBasedVideoAd:weakSelf];
      if (success) {
        GADAdReward *reward = [[GADAdReward alloc]
            initWithRewardType:name
                  rewardAmount:(NSDecimalNumber *)[NSDecimalNumber numberWithInt:amount]];
        [weakSelf.rewardConnector adapter:weakSelf didRewardUserWithReward:reward];
      }
    }];
  }

  if (![self.ad showWithPresentingViewController:rootViewController]) {
    NSLog(@"AdColonyAdapter [Info] : Failed to show ad.");
  }
}

#pragma mark - Banner

- (void)getBannerWithSize:(GADAdSize)adSize {
  NSError *error =
      [NSError errorWithDomain:kGADErrorDomain
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
