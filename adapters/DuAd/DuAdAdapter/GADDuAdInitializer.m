//
//  GADDuAdInitializer.m
//  Adapter
//

@import DUModuleSDK;

#import "GADDuAdInitializer.h"
#import "GADDuAdNetworkExtras.h"
#import "GADMAdapterDuAdConstants.h"

@interface GADDuAdInitializer ()

@property(nonatomic, strong) NSSet *m_nativeIds;

@end

@implementation GADDuAdInitializer

+ (id)sharedInstance {
  static dispatch_once_t once;
  static id instance;
  dispatch_once(&once, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (id)init {
  self = [super init];
  if (self) {
    if (!self.m_nativeIds) {
      self.m_nativeIds = [[NSSet alloc] init];
    }
  }
  return self;
}

- (void)initializeWithConnector:(id<GADMAdNetworkConnector>)connector {
  if (connector) {
    id obj = [connector networkExtras];
    GADDuAdNetworkExtras *networkExtras =
        [obj isKindOfClass:[GADDuAdNetworkExtras class]] ? obj : nil;
    NSString *appId = connector.credentials[kGADMAdapterDuAdAppID];
    NSString *placementID = connector.credentials[kGADMAdapterDuAdPlacementID];

    if (appId) {
      NSMutableSet *args = [[NSMutableSet alloc] init];

      if (networkExtras && networkExtras.placementIds) {
        [args addObjectsFromArray:networkExtras.placementIds];
      }

      if (placementID && ![args containsObject:placementID]) {
        [args addObject:placementID];
      }

      [self initializeWithAppID:appId placmentIDs:args];
    }
  }
}

- (void)initializeWithAppID:(NSString *)appID placmentIDs:(NSMutableSet *)placementIDs {
  BOOL hasNewPlacementIDs = ![placementIDs isSubsetOfSet:self.m_nativeIds];
  if (hasNewPlacementIDs) {
    self.m_nativeIds = [self.m_nativeIds setByAddingObjectsFromSet:placementIDs];
    NSMutableArray *nativeIds = [[NSMutableArray alloc] init];
    for (NSString *pid in self.m_nativeIds) {
      NSDictionary *nativeId = @{@"pid": pid};
      [nativeIds addObject:nativeId];
    }
    NSDictionary *config = [NSDictionary dictionaryWithObject:nativeIds forKey:@"native"];
    [DUAdNetwork initWithConfigDic:config withLicense:appID];
  }
}

@end
