#import "VungleRouter.h"
#import "VungleRouterConsent.h"

static NSString *const vungleAdapterVersion = @"6.3.2.0";

@interface VungleRouter ()
@property(strong) NSMutableArray<id<VungleDelegate>> *delegates;
@property(strong) NSMutableArray<id<VungleDelegate>> *initializingDelegates;
@property(strong) id<VungleDelegate> playingDelegate;
@end

@implementation VungleRouter

+ (NSString *)adapterVersion {
  return vungleAdapterVersion;
}

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
    _delegates = [NSMutableArray array];
    _initializingDelegates = [NSMutableArray array];
  }
  return self;
}

- (void)initWithAppId:(NSString *)appId
             delegate:(id<VungleDelegate>)delegate {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSString *version = [[VungleRouter adapterVersion] stringByReplacingOccurrencesOfString:@"."
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

+ (void)parseServerParameters:(NSDictionary *)serverParameters
                networkExtras:(VungleAdNetworkExtras *)networkExtras
                       result:(ParameterCB)result {
  if ([networkExtras.allPlacements count] > 0) {
    NSLog(@"No need to pass placement IDs through `VungleAdNetworkExtras` with Vungle iOS SDK "
          @"version %@ and plugin version %@",
          VungleSDKVersion, vungleAdapterVersion);
  }

  NSString *appId = serverParameters[kApplicationID];
  if (!appId) {
    NSString *const message = @"Vungle app ID should be specified!";
    NSLog(message);
    result(@{NSLocalizedDescriptionKey : message}, nil);
    return;
  }

  result(nil, appId);
}

+ (NSString *)findPlacement:(NSDictionary *)serverParameters
              networkExtras:(VungleAdNetworkExtras *)networkExtras {
  NSString *ret = [serverParameters objectForKey:kPlacementID];
  if (networkExtras && networkExtras.playingPlacement) {
    if (ret) {
      NSLog(@"'placementID' had a value in both serverParameters and networkExtras. Used one from "
            @"serverParameters");
    } else {
      ret = networkExtras.playingPlacement;
    }
  }

  return ret;
}

- (void)addDelegate:(id<VungleDelegate>)delegate {
  if (delegate && ![_delegates containsObject:delegate]) {
    [_delegates addObject:delegate];
  }
}

- (NSMutableArray *)getDelegates {
  return _delegates;
}

- (void)removeDelegate:(id<VungleDelegate>)delegate {
  if (delegate && [_delegates containsObject:delegate]) {
    [_delegates removeObject:delegate];
  }
}

- (void)notifyAdIsReady:(NSString *)placement {
  for (id<VungleDelegate> item in _delegates) {
    if ([placement isEqualToString:item.desiredPlacement]) {
      [item adAvailable];
    }
  }
}

- (void)loadAd:(NSString *)placement {
  if (placement) {
    VungleSDK *sdk = [VungleSDK sharedSDK];
    if ([sdk isAdCachedForPlacementID:placement]) {
      [self notifyAdIsReady:placement];
      return;
    }
    [sdk loadPlacementWithID:placement error:nil];
  }
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
    NSLog(@"Adapter failed to present reward based video ad, error %@",
          [error localizedDescription]);
    startPlaying = false;
  };
  if (startPlaying) {
    _playingDelegate = delegate;
  }
  return startPlaying;
}

- (void)initialized:(BOOL)isSuccess error:(NSError *)error {
  _isInitialising = false;
  for (id<VungleDelegate> item in _initializingDelegates) {
    [item initialized:isSuccess error:error];
  }
}

#pragma mark - VungleSDKDelegate methods

- (void)vungleWillShowAdForPlacementID:(nullable NSString *)placementID {
  if (_playingDelegate) {
    [_playingDelegate willShowAd];
  }
}

- (void)vungleWillCloseAdWithViewInfo:(nonnull VungleViewInfo *)info
                          placementID:(nonnull NSString *)placementID {
  if (_playingDelegate) {
    [_playingDelegate willCloseAd:[info.completedView boolValue]
                      didDownload:[info.didDownload boolValue]];
  }
}

- (void)vungleDidCloseAdWithViewInfo:(VungleViewInfo *)info placementID:(NSString *)placementID {
  if (_playingDelegate) {
    [_playingDelegate didCloseAd:[info.completedView boolValue]
                     didDownload:[info.didDownload boolValue]];
  }
}

- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable
                      placementID:(NSString *)placementID
                            error:(NSError *)error {
  if (isAdPlayable) {
    [self notifyAdIsReady:placementID];
  } else if (error) {
    // do we want to do anything with the error here?
    NSLog(@"Vungle Ad Playability returned an error: %@", error.localizedDescription);
  }
}

- (void)vungleSDKDidInitialize {
  VungleSDK *sdk = [VungleSDK sharedSDK];
  if ([VungleRouterConsent getConsentStatus] > 0) {
    [sdk updateConsentStatus:[VungleRouterConsent getConsentStatus] consentMessageVersion:@""];
  }

  [self initialized:true error:nil];
}

@end
