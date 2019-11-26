//
//  GADMediationAdapterVerizon.m
//
// @copyright Copyright (c) 2018 Verizon. All rights reserved.
//

#import "GADMediationAdapterVerizon.h"
#import "GADMAdapterVerizonConstants.h"
#import "GADMAdapterVerizonRewardedAd.h"
#import "GADMAdapterVerizonUtils.h"
#import "GADMVerizonConsent_Internal.h"

@implementation GADMediationAdapterVerizon {
  GADMAdapterVerizonRewardedAd *_rewardedAd;
}

- (id)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super initWithGADMAdNetworkConnector:connector];
  if (self) {
    [self initializeVASAds];
  }
  return self;
}

- (void)initializeVASAds {
  // Position.
  NSDictionary *credentials = [self.connector credentials];
  if (credentials[kGADMAdapterVerizonMediaPosition]) {
    self.placementID = credentials[kGADMAdapterVerizonMediaPosition];
  }

  if (![VASAds.sharedInstance isInitialized]) {
    // Site ID.
    NSString *siteID = credentials[kGADMAdapterVerizonMediaDCN];
    if (!siteID.length) {
      siteID = [[NSBundle mainBundle] objectForInfoDictionaryKey:kGADMAdapterVerizonMediaSiteID];
    }
    [VASStandardEdition initializeWithSiteId:siteID];
  }

  if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0) {
    VASAds.logLevel = VASLogLevelError;
    self.vasAds = VASAds.sharedInstance;
    [GADMVerizonConsent.sharedInstance updateConsentInfo];
  }
}

#pragma mark - GADMediationAdapter

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet *siteIDs = [[NSMutableSet alloc] init];

  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *siteID = cred.settings[kGADMAdapterVerizonMediaDCN];
    GADMAdapterVerizonMutableSetAddObject(siteIDs, siteID);
  }

  if (!siteIDs.count) {
    NSString *errorString = @"Verizon media mediation configurations did not contain a valid site ID.";
    NSError *error = [NSError errorWithDomain:kGADMAdapterVerizonMediaErrorDomain
                                         code:kGADErrorMediationAdapterError
                                     userInfo:@{ NSLocalizedDescriptionKey : errorString }];
    completionHandler(error);
    return;
  }

  NSString *siteID = [siteIDs anyObject];

  if (siteIDs.count != 1) {
    NSLog(@"Found the following site IDs: %@. Please remove any site IDs you are not using from"
          @"the AdMob/Ad Manager UI.", siteIDs);
    NSLog(@"Initializing Verizon media SDK with the site ID %@", siteID);
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    [VASStandardEdition initializeWithSiteId:siteID];
  });
  completionHandler(nil);
}

+ (GADVersionNumber)version {
  NSArray<NSString *> *versionComponents =
      [kGADMAdapterVerizonMediaVersion componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [VASAds.sharedInstance.configuration stringForDomain:@"com.verizon.ads"
                                                                             key:@"editionVersion"
                                                                     withDefault:nil];
  if (!versionString.length) {
    versionString = VASAds.sdkInfo.version;
  }

  NSArray<NSString *> *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 3) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion = [versionComponents[2] integerValue];
  }
  return version;
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
  _rewardedAd = [[GADMAdapterVerizonRewardedAd alloc] init];
  [_rewardedAd loadRewardedAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

@end
