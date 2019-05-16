#import "GADMediationAdapterMoPub.h"

#import "GADMAdapterMoPubSingleton.h"
#import "GADMMoPubRewardedAd.h"
#import "GADMoPubNetworkExtras.h"
#import "MPRewardedVideo.h"
#import "MoPub.h"
#import "MoPubAdapterConstants.h"

@interface GADMediationAdapterMoPub () <MPRewardedVideoDelegate>

@property(nonatomic, strong) GADMMoPubRewardedAd *rewardedAd;

@end

@implementation GADMediationAdapterMoPub

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSString *adUnitID;
  if (configuration.credentials.count > 0) {
    adUnitID = configuration.credentials[0].settings[kGADMAdapterMoPubPubIdKey];
  }

  if (adUnitID) {
    [[GADMAdapterMoPubSingleton sharedInstance] initializeMoPubSDKWithAdUnitID:adUnitID
                                                             completionHandler:^{
                                                               completionHandler(nil);
                                                             }];
  } else {
    NSString *description = @"Failed to initialize MoPub SDK. Ad unit ID is empty.";
    NSDictionary *userInfo =
        @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};

    NSError *error = [NSError errorWithDomain:kGADMAdapterMoPubErrorDomain
                                         code:0
                                     userInfo:userInfo];
    completionHandler(error);
  }
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [[MoPub sharedInstance] version];
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
  return [GADMoPubNetworkExtras class];
}

+ (GADVersionNumber)version {
  NSArray *versionComponents = [kGADMAdapterMoPubVersion componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (versionComponents.count == 3) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  self.rewardedAd = [[GADMMoPubRewardedAd alloc] init];
  [self.rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                                  completionHandler:completionHandler];
}

@end
