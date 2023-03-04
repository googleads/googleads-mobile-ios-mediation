// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterMintegralUtils.h"
#import "GADMediationAdapterMintegralConstants.h"

@implementation GADMAdapterMintegralUtils

NSError *_Nonnull GADMAdapterMintegralErrorWithCodeAndDescription(GADMintegralErrorCode code,
                                                                  NSString *_Nonnull description) {
  return [NSError errorWithDomain:GADMAdapterMintegralErrorDomain
                             code:code
                         userInfo:@{
                           NSLocalizedDescriptionKey : description,
                           NSLocalizedFailureReasonErrorKey : description
                         }];
}

void GADMAdapterMintegralMutableSetAddObject(NSMutableSet *_Nullable set,
                                             NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

/// Returns the closest valid banner size by comparing the provided ad size against the valid sizes.
/// Returns CGSizeZero and sets |error| if the ad configuration contains an invalid ad size.
+ (CGSize)bannerSizeFromAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                                  error:(NSError **)errorPtr {
  GADAdSize adSize320x50 = GADAdSizeFromCGSize(CGSizeMake(320, 50));
  GADAdSize adSize320x100 = GADAdSizeFromCGSize(CGSizeMake(320, 100));
  GADAdSize adSize300x250 = GADAdSizeFromCGSize(CGSizeMake(300, 250));
  GADAdSize adSize728x90 = GADAdSizeFromCGSize(CGSizeMake(728, 90));
  NSArray<NSValue *> *possibleSizes =
      @[ @(adSize320x50), @(adSize320x100), @(adSize300x250), @(adSize728x90) ];

  GADAdSize requestedSize = adConfiguration.adSize;
  GADAdSize closestAdSize = GADClosestValidSizeForAdSizes(requestedSize, possibleSizes);

  if (GADAdSizeEqualToSize(closestAdSize, GADAdSizeInvalid)) {
    NSString *errorMessage = [NSString
        stringWithFormat:@"The requested banner size: %@ is not supported by Mintegral SDK.",
                         NSStringFromGADAdSize(requestedSize)];
    *errorPtr = GADMAdapterMintegralErrorWithCodeAndDescription(GADMintegtalErrorBannerSizeInValid,
                                                                errorMessage);
    return CGSizeZero;
  }

  return CGSizeMake(closestAdSize.size.width, closestAdSize.size.height);
}

+ (void)downLoadNativeAdImageWithURLString:(NSString *_Nonnull)URLString
                         completionHandler:
                             (void (^_Nullable)(GADNativeAdImage *_Nullable nativeAdImage))
                                 completionHandler {
  if (!URLString.length) {
    completionHandler(nil);
    return;
  }

  NSURL *URL = [NSURL URLWithString:URLString];
  if (!URL) {
    completionHandler(nil);
    return;
  }

  NSURLSession *session = [NSURLSession sharedSession];
  NSURLSessionDataTask *task =
      [session dataTaskWithURL:URL
             completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response,
                                 NSError *_Nullable error) {
               dispatch_async(dispatch_get_main_queue(), ^{
                 GADNativeAdImage *image =
                     (!error && data)
                         ? [[GADNativeAdImage alloc] initWithImage:[UIImage imageWithData:data]]
                         : nil;
                 completionHandler(image);
               });
             }];
  [task resume];
}

@end
