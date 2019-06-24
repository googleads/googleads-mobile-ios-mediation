#import "VungleRouter.h"
#import "GADMAdapterVungleConstants.h"
#import "VungleRouterConsent.h"

@interface VungleRouter ()
@property(strong) NSMapTable<NSString *, id<VungleDelegate>> *delegates;
@property(strong) NSMapTable<NSString *, id<VungleDelegate>> *initializingDelegates;
@property(strong) NSMapTable<NSString *, id<VungleDelegate>> *bannerDelegates;
@property(nonatomic, assign) BOOL isMrecPlaying;
@property(nonatomic, copy) NSString *mrecPlacementID;
@end

@implementation VungleRouter

+ (VungleRouter *)sharedInstance {
  static VungleRouter *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[VungleRouter alloc] init];
  });
  return instance;
}

- (id)init {
  self = [super init];
  if (self) {
    [VungleSDK sharedSDK].delegate = self;
    self.delegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                           valueOptions:NSPointerFunctionsWeakMemory];
    self.initializingDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                       valueOptions:NSPointerFunctionsWeakMemory];
    self.bannerDelegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                                 valueOptions:NSPointerFunctionsWeakMemory];
  }
  return self;
}

- (void)initWithAppId:(NSString *)appId delegate:(id<VungleDelegate>)delegate {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSString *version =
        [kGADMAdapterVungleVersion stringByReplacingOccurrencesOfString:@"." withString:@"_"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [[VungleSDK sharedSDK] performSelector:@selector(setPluginName:version:)
                                withObject:@"admob"
                                withObject:version];
#pragma clang diagnostic pop
  });
  VungleSDK *sdk = [VungleSDK sharedSDK];

  if (delegate) {
    [self.initializingDelegates setObject:delegate forKey:delegate.desiredPlacement];
  }

  if ([sdk isInitialized]) {
    [self initialized:true error:nil];
    return;
  }

  if ([self isInitialising]) {
    return;
  }

  _isInitialising = true;
  _isMrecPlaying = NO;

  NSError *err = nil;
  [sdk startWithAppId:appId error:&err];
  if (err) {
    [self initialized:false error:err];
  }
}

- (BOOL)isSDKInitialized {
  return [[VungleSDK sharedSDK] isInitialized];
}

- (BOOL)isAdCachedForPlacementID:(NSString *)placementID {
  return [[VungleSDK sharedSDK] isAdCachedForPlacementID:placementID];
}

- (void)addDelegate:(id<VungleDelegate>)delegate {
  if (delegate.adapterAdType == Interstitial || delegate.adapterAdType == Rewarded) {
    @synchronized(self.delegates) {
      if (delegate && ![self.delegates objectForKey:delegate.desiredPlacement]) {
        [self.delegates setObject:delegate forKey:delegate.desiredPlacement];
      }
    }
  } else if (delegate.adapterAdType == MREC) {
    @synchronized(self.bannerDelegates) {
      self.mrecPlacementID = [delegate.desiredPlacement copy];
      if (delegate && ![self.bannerDelegates objectForKey:delegate.desiredPlacement]) {
        [self.bannerDelegates setObject:delegate forKey:delegate.desiredPlacement];
      }
    }
  }
}

- (id<VungleDelegate>)getDelegateForPlacement:(NSString *)placement {
  id<VungleDelegate> delegate;
  if ([placement isEqualToString:self.mrecPlacementID]) {
    @synchronized(self.bannerDelegates) {
      if ([self.bannerDelegates objectForKey:placement]) {
        delegate = [self.bannerDelegates objectForKey:placement];
        if (delegate.bannerState != BannerRouterDelegateStateRequesting) {
          delegate = nil;
        }
      }
    }
  } else {
    @synchronized(self.delegates) {
      if ([self.delegates objectForKey:placement]) {
        delegate = [self.delegates objectForKey:placement];
      }
    }
  }

  return delegate;
}

- (void)removeDelegate:(id<VungleDelegate>)delegate {
  if (delegate.adapterAdType == Interstitial || delegate.adapterAdType == Rewarded) {
    @synchronized(self.delegates) {
      if (delegate && [self.delegates objectForKey:delegate.desiredPlacement]) {
        [self.delegates removeObjectForKey:delegate.desiredPlacement];
      }
    }
  } else if (delegate.adapterAdType == MREC) {
    @synchronized(self.bannerDelegates) {
      if (delegate && [self.bannerDelegates objectForKey:delegate.desiredPlacement]) {
        [self.bannerDelegates removeObjectForKey:delegate.desiredPlacement];
      }
    }
  }
}

- (BOOL)hasDelegateForPlacementID:(NSString *)placementID
                      adapterType:(VungleNetworkAdapterAdType)adapterType {
  BOOL result = NO;
  NSMapTable<NSString *, id<VungleDelegate>> *delegates;
  if ([self isSDKInitialized]) {
    delegates = [self.delegates copy];
  } else {
    delegates = [self.initializingDelegates copy];
  }

  for (NSString *key in delegates) {
    id<VungleDelegate> delegate = [delegates objectForKey:key];
    if (delegate.adapterAdType == adapterType &&
        [delegate.desiredPlacement isEqualToString:placementID]) {
      result = YES;
      break;
    }
  }

  return result;
}

- (BOOL)canRequestBannerAdForPlacementID:(NSString *)placmentID {
  return self.mrecPlacementID == nil || [self.mrecPlacementID isEqualToString:placmentID];
}

- (NSError *)loadAd:(NSString *)placement withDelegate:(id<VungleDelegate>)delegate {
  id<VungleDelegate> adapterDelegate = [self getDelegateForPlacement:placement];
  if (adapterDelegate) {
    NSError *error =
        [NSError errorWithDomain:kGADMAdapterVungleErrorDomain
                            code:0
                        userInfo:@{
                          NSLocalizedDescriptionKey :
                              @"Can't request ad if another request is in processing."
                        }];
    return error;
  } else {
    [self addDelegate:delegate];
  }

  VungleSDK *sdk = [VungleSDK sharedSDK];
  if ([sdk isAdCachedForPlacementID:placement]) {
    [delegate adAvailable];
  } else {
    NSError *loadError;
    if (![sdk loadPlacementWithID:placement error:&loadError]) {
      if (loadError) {
        return loadError;
      }
    }
  }

  return nil;
}

- (BOOL)playAd:(UIViewController *)viewController
      delegate:(id<VungleDelegate>)delegate
        extras:(VungleAdNetworkExtras *)extras {
  if (!delegate || !delegate.desiredPlacement ||
      ![[VungleSDK sharedSDK] isAdCachedForPlacementID:delegate.desiredPlacement]) {
    return false;
  }
  NSMutableDictionary *options = [[NSMutableDictionary alloc] init];  //
  NSError *error = nil;
  bool didAdStartPlaying = true;
  [VungleSDK sharedSDK].muted = extras.muted;
  if (extras.userId) [options setObject:extras.userId forKey:VunglePlayAdOptionKeyUser];
  if (extras.ordinal) [options setObject:@(extras.ordinal) forKey:VunglePlayAdOptionKeyOrdinal];
  if (extras.flexViewAutoDismissSeconds)
    [options setObject:@(extras.flexViewAutoDismissSeconds)
                forKey:VunglePlayAdOptionKeyFlexViewAutoDismissSeconds];
  if (![[VungleSDK sharedSDK] playAd:viewController
                             options:options
                         placementID:delegate.desiredPlacement
                               error:&error]) {
    didAdStartPlaying = false;
  }
  if (error) {
    NSLog(@"Adapter failed to present ad, error %@", [error localizedDescription]);
    didAdStartPlaying = false;
  }

  return didAdStartPlaying;
}

- (UIView *)renderBannerAdInView:(UIView *)bannerView
                        delegate:(id<VungleDelegate>)delegate
                          extras:(VungleAdNetworkExtras *)extras
                  forPlacementID:(NSString *)placementID {
  NSError *bannerError = nil;
  NSMutableDictionary *options = [[NSMutableDictionary alloc] init];  ///
  if (extras.muted) {
    [VungleSDK sharedSDK].muted = extras.muted;
  } else {
    [VungleSDK sharedSDK].muted = YES;
  }
  if (extras.userId) [options setObject:extras.userId forKey:VunglePlayAdOptionKeyUser];
  if (extras.ordinal) [options setObject:@(extras.ordinal) forKey:VunglePlayAdOptionKeyOrdinal];
  if (extras.flexViewAutoDismissSeconds)
    [options setObject:@(extras.flexViewAutoDismissSeconds)
                forKey:VunglePlayAdOptionKeyFlexViewAutoDismissSeconds];

  BOOL success = [[VungleSDK sharedSDK] addAdViewToView:bannerView
                                            withOptions:options
                                            placementID:placementID
                                                  error:&bannerError];
  if (success) {
    self.isMrecPlaying = YES;

    return bannerView;
  } else {
    NSLog(@"Banner loading error: %@", bannerError.localizedDescription);
    self.isMrecPlaying = NO;

    return nil;
  }

  return nil;
}

- (void)completeBannerAdViewForPlacementID:(NSString *)placementID {
  if (placementID && self.isMrecPlaying) {
    NSLog(@"Vungle: Triggering an ad completion call for %@", placementID);
    self.isMrecPlaying = NO;

    [[VungleSDK sharedSDK] finishedDisplayingAd];
  }
}

- (void)initialized:(BOOL)isSuccess error:(NSError *)error {
  _isInitialising = false;
  NSMapTable<NSString *, id<VungleDelegate>> *delegates = [self.initializingDelegates copy];
  for (NSString *key in delegates) {
    id<VungleDelegate> delegate = [delegates objectForKey:key];
    [delegate initialized:isSuccess error:error];
  }

  [self.initializingDelegates removeAllObjects];
}

#pragma mark - VungleSDKDelegate methods

- (void)vungleWillShowAdForPlacementID:(nullable NSString *)placementID {
  id<VungleDelegate> delegate = [self getDelegateForPlacement:placementID];
  if (delegate) {
    [delegate willShowAd];
  }
}

- (void)vungleWillCloseAdWithViewInfo:(nonnull VungleViewInfo *)info
                          placementID:(nonnull NSString *)placementID {
  id<VungleDelegate> delegate = [self getDelegateForPlacement:placementID];
  if (delegate) {
    [delegate willCloseAd:[info.completedView boolValue] didDownload:[info.didDownload boolValue]];
  }
}

- (void)vungleDidCloseAdWithViewInfo:(VungleViewInfo *)info placementID:(NSString *)placementID {
  id<VungleDelegate> delegate = [self getDelegateForPlacement:placementID];
  if (delegate) {
    [self removeDelegate:delegate];
    [delegate didCloseAd:[info.completedView boolValue] didDownload:[info.didDownload boolValue]];
  }
}

- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable
                      placementID:(NSString *)placementID
                            error:(NSError *)error {
  id<VungleDelegate> delegate = [self getDelegateForPlacement:placementID];
  if (!delegate) {
    return;
  }
  if (isAdPlayable) {
    [delegate adAvailable];
  } else if (error) {
    NSLog(@"Vungle Ad Playability returned an error: %@", error.localizedDescription);
    [self removeDelegate:delegate];
    [delegate adNotAvailable:error];
  }
}

- (void)vungleSDKDidInitialize {
  VungleSDK *sdk = [VungleSDK sharedSDK];
  if ([VungleRouterConsent getConsentStatus] > 0) {
    [sdk updateConsentStatus:[VungleRouterConsent getConsentStatus] consentMessageVersion:@""];
  }

  [self initialized:true error:nil];
}

- (void)vungleSDKFailedToInitializeWithError:(NSError *)error {
  [self initialized:false error:error];
}

@end
