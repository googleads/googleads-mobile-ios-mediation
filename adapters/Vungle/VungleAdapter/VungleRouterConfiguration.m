//
//  VungleRouterConfiguration.m
//  VungleAdapter
//
//  Created by Akifumi Shinagawa on 2/12/19.
//  Copyright © 2019 Vungle. All rights reserved.
//

#import "VungleRouterConfiguration.h"
#import <VungleSDK/VungleSDK.h>

// These keys are also defined in VNGPersisteceManager.
static NSString *const kAdapterMinimumFileSystemSizeForInit = @"vungleMinimumFileSystemSizeForInit";
static NSString *const kAdapterMinimumFileSystemSizeForAdRequest =
    @"vungleMinimumFileSystemSizeForAdRequest";
static NSString *const kAdapterMinimumFileSystemSizeForAssetDownload =
    @"vungleMinimumFileSystemSizeForAssetDownload";

@implementation VungleRouterConfiguration

+ (void)setPublishIDFV:(BOOL)publish {
  [VungleSDK setPublishIDFV:publish];
}

+ (void)setMinSpaceForInit:(int)size {
  if (size >= 0) {
    [[NSUserDefaults standardUserDefaults] setInteger:size
                                               forKey:kAdapterMinimumFileSystemSizeForInit];
  } else {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kAdapterMinimumFileSystemSizeForInit];
  }
  [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)setMinSpaceForAdLoad:(int)size {
  if (size >= 0) {
    [[NSUserDefaults standardUserDefaults] setInteger:size
                                               forKey:kAdapterMinimumFileSystemSizeForAdRequest];
    [[NSUserDefaults standardUserDefaults]
        setInteger:size
            forKey:kAdapterMinimumFileSystemSizeForAssetDownload];
  } else {
    [[NSUserDefaults standardUserDefaults]
        removeObjectForKey:kAdapterMinimumFileSystemSizeForAdRequest];
    [[NSUserDefaults standardUserDefaults]
        removeObjectForKey:kAdapterMinimumFileSystemSizeForAssetDownload];
  }
  [[NSUserDefaults standardUserDefaults] synchronize];
}
@end
