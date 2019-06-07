#import "VungleRouter.h"
#import "GADMAdapterVungleConstants.h"
#import "VungleRouterConsent.h"

@interface VungleRouter ()
@property(strong) NSMapTable<NSString *, id<VungleDelegate>> *delegates;
@property(strong) NSMutableArray<id<VungleDelegate>> *initializingDelegates;
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
    _delegates = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                       valueOptions:NSPointerFunctionsWeakMemory];
    _initializingDelegates = [NSMutableArray array];
  }
  return self;
}

- (void)initWithAppId:(NSString *)appId delegate:(id<VungleDelegate>)delegate {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSString *version = [kGADMAdapterVungleVersion stringByReplacingOccurrencesOfString:@"."
                                                                             withString:@"_"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [[VungleSDK sharedSDK] performSelector:@selector(setPluginName:version:)
                                withObject:@"admob"
                                withObject:version];
#pragma clang diagnostic pop
  });
  VungleSDK *sdk = [VungleSDK sharedSDK];

  if (delegate) {
    [self.initializingDelegates addObject:delegate];
  }

  if ([sdk isInitialized]) {
    [self initialized:true error:nil];
    return;
  }

  if ([self isInitialising]) {
    return;
  }

  _isInitialising = true;

  NSError *err = nil;
  [sdk startWithAppId:appId error:&err];
  if (err) {
    [self initialized:false error:err];
  }
}

- (void)addDelegate:(id<VungleDelegate>)delegate {
  @synchronized(self.delegates) {
    [_delegates setObject:delegate forKey:delegate.desiredPlacement];
  }
}

- (id<VungleDelegate>)getDelegateForPlacement:(NSString *)placement {
  @synchronized(self.delegates) {
    return [_delegates objectForKey:placement];
  }
}

- (void)removeDelegateForPlacementID:(NSString *)placementID {
  @synchronized(self.delegates) {
    [_delegates removeObjectForKey:placementID];
  }
}

- (NSError *)loadAd:(NSString *)placement withDelegate:(id<VungleDelegate>)delegate {
  id<VungleDelegate> adapterDelegate = [self getDelegateForPlacement:placement];
  if (adapterDelegate) {
    NSError *error = [NSError errorWithDomain:kGADMAdapterVungleErrorDomain
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
    [sdk loadPlacementWithID:placement error:nil];
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
  NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
  NSError *error = nil;
  bool startPlaying = true;
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
    startPlaying = false;
  }
  if (error) {
    NSLog(@"Adapter failed to present ad, error %@", [error localizedDescription]);
    startPlaying = false;
  };
  return startPlaying;
}

- (void)initialized:(BOOL)isSuccess error:(NSError *)error {
  _isInitialising = false;
  NSArray<id<VungleDelegate>> *delegates = [_initializingDelegates copy];
  for (id<VungleDelegate> item in delegates) {
    [item initialized:isSuccess error:error];
  }
  [_initializingDelegates removeObjectsInArray:delegates];
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
  [self removeDelegateForPlacementID:placementID];
  if (delegate) {
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
    [self removeDelegateForPlacementID:placementID];
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
