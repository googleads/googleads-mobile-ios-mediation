//
//  GADMAdapterVungleUtils.m
//  Copyright © 2019 Google. All rights reserved.
//

#import "GADMAdapterVungleUtils.h"
#import "GADMAdapterVungleConstants.h"

void GADMAdapterVungleMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

void GADMAdapterVungleMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                              id<NSCopying> _Nullable key, id _Nullable value) {
  if (value && key) {
    [mapTable setObject:value forKey:key];  // Allow pattern.
  }
}

void GADMAdapterVungleMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable, id _Nullable key) {
  if (key) {
    [mapTable removeObjectForKey:key];  // Allow pattern.
  }
}

@implementation GADMAdapterVungleUtils

+ (NSString *)findAppID:(NSDictionary *)serverParameters {
  NSString *appId = serverParameters[kGADMAdapterVungleApplicationID];
  if (!appId) {
    NSString *const message = @"Vungle app ID should be specified!";
    NSLog(message);
    return nil;
  }
  return appId;
}

+ (NSString *)findPlacement:(NSDictionary *)serverParameters
              networkExtras:(VungleAdNetworkExtras *)networkExtras {
  NSString *ret = serverParameters[kGADMAdapterVunglePlacementID];
  if (networkExtras && networkExtras.playingPlacement) {
    if (ret) {
      NSLog(@"'placementID' had a value in both serverParameters and networkExtras. "
            @"Used one from serverParameters.");
    } else {
      ret = networkExtras.playingPlacement;
    }
  }

  return ret;
}

@end
