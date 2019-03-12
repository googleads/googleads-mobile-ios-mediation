//
//  Copyright © 2018 Google. All rights reserved.
//

#import "GADMediationAdapterAdColony.h"
#import <AdColony/AdColony.h>
#import "GADMAdapterAdColonyExtras.h"
#import "GADMAdapterAdColonyInitializer.h"
#import "GADMAdapterAdColonyRewardedAd.h"

NSString *const kGADMAdapterAdColonyVersionString = @"3.3.6.1";
NSString *const kGADMAdapterAdColonyAppIDkey = @"app_id";
NSString *const kGADMAdapterAdColonyZoneIDkey = @"zone_ids";

@interface GADMediationAdapterAdColony ()

@property(nonatomic, strong) GADMAdapterAdColonyRewardedAd *rewardedAd;
@end

@implementation GADMediationAdapterAdColony

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet *zoneIDs = [[NSMutableSet alloc] init];
  NSMutableSet *appIDs = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *cred in configuration.credentials) {
    [zoneIDs addObject:[cred.settings objectForKey:kGADMAdapterAdColonyZoneIDkey]];
    [appIDs addObject:[cred.settings objectForKey:kGADMAdapterAdColonyAppIDkey]];
  }

  NSString *appID = [appIDs anyObject];

  if (appIDs.count != 1) {
    NSLog(@"Found the following app IDs: %@. Please remove any app IDs you are not using from the "
          @"AdMob UI.",
          appIDs);
    NSLog(@"Configuring AdColony SDK with the app ID %@", appID);
  }

  [[GADMAdapterAdColonyInitializer sharedInstance]
    initializeAdColonyWithAppId:appID
                          zones:[zoneIDs allObjects]
                        options:nil
                       callback:^(NSError *error) {
                         completionHandler(error);
                        }];
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [AdColony getSDKVersion];
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count == 3) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion = [versionComponents[2] integerValue];
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterAdColonyExtras class];
}

+ (GADVersionNumber)version {
  NSString *versionString = kGADMAdapterAdColonyVersionString;
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count == 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:(GADRewardedLoadCompletionHandler)completionHandler {
  self.rewardedAd = [[GADMAdapterAdColonyRewardedAd alloc] init];
  [self.rewardedAd renderRewardedAdForAdConfiguration:adConfiguration
                                    completionHandler:completionHandler];
}

@end
