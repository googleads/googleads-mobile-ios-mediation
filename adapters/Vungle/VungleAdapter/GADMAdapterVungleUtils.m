//
//  GADMAdapterVungleUtils.m
//  Copyright © 2019 Google. All rights reserved.
//

#import "GADMAdapterVungleUtils.h"
#import "GADMAdapterVungleConstants.h"

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
  NSString *ret = [serverParameters objectForKey:kGADMAdapterVunglePlacementID];
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

@end
