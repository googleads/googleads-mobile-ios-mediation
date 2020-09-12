// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <CoreLocation/CoreLocation.h>

#import "GADMAdapterFyberConstants.h"
#import "GADMAdapterFyberUtils.h"
#import "GADMAdapterFyberExtras.h"

void GADMAdapterFyberMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

NSError *_Nonnull GADMAdapterFyberErrorWithCodeAndDescription(NSInteger code,
                                                              NSString *_Nonnull description) {
  NSDictionary<NSString *, NSString *> *info = @{NSLocalizedDescriptionKey : description};
  return [NSError errorWithDomain:kGADMAdapterFyberErrorDomain code:code userInfo:info];
}

GADVersionNumber GADMAdapterFyberVersionFromString(NSString *_Nonnull versionString) {
  NSArray<NSString *> *versionAsArray = [versionString componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};

  if (versionAsArray.count >= 3) {
    version.majorVersion = versionAsArray[0].integerValue;
    version.minorVersion = versionAsArray[1].integerValue;
    version.patchVersion = versionAsArray[2].integerValue;

    if (versionAsArray.count >= 4) {
      version.patchVersion = version.patchVersion * 100 + versionAsArray[3].integerValue;
    }
  }
  return version;
}

IAAdRequest *_Nonnull GADMAdapterFyberBuildRequestWithSpotIDAndConnector(
    NSString *_Nonnull spotID, id<GADMAdNetworkConnector> _Nonnull connector) {
  GADMAdapterFyberExtras *extras = nil;
  if (connector.networkExtras) {
    extras = connector.networkExtras;
  }

  NSString *keywords = nil;
  if (connector.userKeywords) {
    keywords = [connector.userKeywords componentsJoinedByString:@" "];
  } else if (extras.keywords) {
    keywords = extras.keywords;
  }

  CLLocation *location;
  if (connector.userHasLocation) {
    location = [[CLLocation alloc] initWithLatitude:connector.userLatitude
                                          longitude:connector.userLongitude];
  }

  return GADMAdapterFyberBuildRequestWithSpotID(spotID, keywords, location, extras.userData);
}

IAAdRequest *_Nonnull GADMAdapterFyberBuildRequestWithSpotIDAndAdConfiguration(
    NSString *_Nonnull spotID, GADMediationRewardedAdConfiguration *_Nonnull adConfiguration) {
  CLLocation *location;
  if (adConfiguration.hasUserLocation) {
    location = [[CLLocation alloc] initWithLatitude:adConfiguration.userLatitude
                                          longitude:adConfiguration.userLongitude];
  }
  
  GADMAdapterFyberExtras *extras = nil;
  NSString *keywords = nil;
  if (adConfiguration.extras) {
    extras = adConfiguration.extras;
  }
    
  if (extras.keywords) {
    keywords = extras.keywords;
  }
    
  return GADMAdapterFyberBuildRequestWithSpotID(spotID, keywords, location, extras.userData);
}

IAAdRequest *_Nonnull GADMAdapterFyberBuildRequestWithSpotID(NSString *_Nonnull spotID,
                                                             NSString *_Nullable keywords,
                                                             CLLocation *_Nullable location,
                                                             IAUserData *_Nullable userData) {
  IAAdRequest *request = [IAAdRequest build:^(id<IAAdRequestBuilder> _Nonnull builder) {
    builder.useSecureConnections = NO;
    builder.spotID = spotID;
    builder.timeout = 10;
    builder.userData = userData;
    if (keywords) {
      builder.keywords = keywords;
    }
    if (location) {
      builder.location = location;
    }
  }];

  return request;
}

BOOL GADMAdapterFyberInitializeWithAppID(NSString *_Nonnull appID,
                                         NSError *__autoreleasing _Nullable *_Nullable error) {
  // If the appID is set, then the Fyber SDK has already been initialized.
  if (IASDKCore.sharedInstance.appID) {
    return YES;
  }

  if (!appID.length) {
    *error = GADMAdapterFyberErrorWithCodeAndDescription(
        kGADErrorInternalError,
        @"Fyber Marketplace SDK could not be initialized; missing or invalid application ID.");
    return NO;
  }

  GADMAdapterFyberLog(@"Configuring Fyber Marketplace SDK with application ID: %@.", appID);
  [IASDKCore.sharedInstance initWithAppID:appID];
  return (IASDKCore.sharedInstance.appID != nil);
}
