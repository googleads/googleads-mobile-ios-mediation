#import "GADMediationAdapterVungle.h"
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleRewardedAd.h"
#import "VungleAdNetworkExtras.h"
#import "VungleRouter.h"

@interface GADMediationAdapterVungle ()
@property(nonatomic, strong) GADMAdapterVungleRewardedAd *rewardedAd;
@end

@implementation GADMediationAdapterVungle

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet *applicationIDs = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *cred in configuration.credentials) {
    [applicationIDs addObject:[cred.settings valueForKey:kGADMAdapterVungleApplicationID]];
  }

  NSString *applicationID = [applicationIDs anyObject];

  if (applicationIDs.count != 1) {
    NSLog(@"Found the following application IDs: %@. Please remove any application IDs you are not "
          @"using from the AdMob UI.",
          applicationIDs);
    NSLog(@"Configuring AdColony SDK with the application ID %@.", applicationID);
  }

  [[VungleRouter sharedInstance] initWithAppId:applicationID delegate:nil];

  completionHandler(nil);
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = VungleSDKVersion;
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
  return [VungleAdNetworkExtras class];
}

+ (GADVersionNumber)version {
  NSString *versionString = kGADMAdapterVungleVersion;
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count == 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    // Adapter versions have 2 patch versions. Multiply the first patch by 100.
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

- (void)dealloc {
  self.rewardedAd = nil;
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  self.rewardedAd = [[GADMAdapterVungleRewardedAd alloc] initWithAdConfiguration:adConfiguration
                                                               completionHandler:completionHandler];
  [self.rewardedAd requestRewardedAd];
}

@end
