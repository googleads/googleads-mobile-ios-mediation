#import "vungleHelper.h"

static NSString *const vungleAdapterVersion = @"5.4.0.0";

static NSString *const kApplicationID = @"application_id";
static NSString *const kPlacementID = @"placementID";

@interface vungleHelper ()
@property(strong) NSMutableArray<id<VungleDelegate>> *delegates;
@property(strong) id<VungleDelegate> playingDelegate;
@end

@implementation vungleHelper

+ (NSString *)adapterVersion {
  return vungleAdapterVersion;
}

+ (vungleHelper *)sharedInstance {
  static vungleHelper *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[vungleHelper alloc] init];
  });
  return instance;
}

- (id)init {
  self = [super init];
  if (self) {
    [VungleSDK sharedSDK].delegate = self;
    _delegates = [NSMutableArray array];
  }
  return self;
}

- (void)initWithAppId:(NSString *)appId placements:(NSArray<NSString *> *)placements {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSString *version =
        [[vungleHelper adapterVersion] stringByReplacingOccurrencesOfString:@"." withString:@"_"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [[VungleSDK sharedSDK] performSelector:@selector(setPluginName:version:)
                                withObject:@"admob"
                                withObject:version];
#pragma clang diagnostic pop
  });
  VungleSDK *sdk = [VungleSDK sharedSDK];
  if ([sdk isInitialized]) {
    [self initialized:true error:nil];
    return;
  }
  if ([self isInitialising]) {
    return;
  }

  _isInitialising = true;

  NSError *err = nil;
  _allPlacements = placements;
  [sdk startWithAppId:appId placements:placements error:&err];
  if (err) {
    [self initialized:false error:err];
  }
}

+ (void)parseServerParameters:(NSDictionary *)serverParameters
                networkExtras:(VungleAdNetworkExtras *)networkExtras
                       result:(ParameterCB)result {
  NSMutableArray *allPlacements = [NSMutableArray array];
  if (networkExtras && networkExtras.allPlacements && [networkExtras.allPlacements count] > 0) {
    [allPlacements addObjectsFromArray:networkExtras.allPlacements];
  }

  if (!serverParameters || ![serverParameters objectForKey:kApplicationID]) {
    NSLog(@"Vungle app ID should be specified!");
    result(@{NSLocalizedDescriptionKey : @"Vungle app ID should be specified!"}, nil, nil);
    return;
  }
  NSString *appId = [serverParameters objectForKey:kApplicationID];

  if (allPlacements.count == 0) {
    NSLog(@"At least one placement should be specified!");
    result(@{NSLocalizedDescriptionKey : @"At least one placement should be specified!"}, nil, nil);
    return;
  }

  result(nil, appId, allPlacements);
}

+ (NSString *)findPlacement:(NSDictionary *)serverParameters
              networkExtras:(VungleAdNetworkExtras *)networkExtras {
  NSString *ret = nil;
  if (serverParameters && [serverParameters objectForKey:kPlacementID]) {
    ret = [serverParameters objectForKey:kPlacementID];
  }
  if (networkExtras && networkExtras.playingPlacement) {
    if (ret) {
      NSLog(
          @"'placementID' had a value in both serverParameters and networkExtras. Used one from "
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
  for (id<VungleDelegate> item in _delegates) {
    if ([item waitingInit]) {
      [item initialized:isSuccess error:error];
    }
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
    [_playingDelegate willCloseAd:[info.completedView boolValue]];
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
  [self initialized:true error:nil];
}

@end
