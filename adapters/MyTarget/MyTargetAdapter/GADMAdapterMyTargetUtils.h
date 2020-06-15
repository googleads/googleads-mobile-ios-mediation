//
//  GADMAdapterMyTargetUtils.h
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 28.09.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MyTargetSDK/MyTargetSDK.h>

#define MTRGLogInfo()                                                                    \
  if (GADMAdapterMyTargetUtils.logEnabled) {                                             \
    NSLog(@"[%@ info] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd)); \
  }
#define MTRGLogDebug(format, ...)                               \
  if (GADMAdapterMyTargetUtils.logEnabled) {                    \
    NSLog(@"[%@ debug] %@", NSStringFromClass([self class]),    \
          [NSString stringWithFormat:(format), ##__VA_ARGS__]); \
  }
#define MTRGLogError(message)                                            \
  if (GADMAdapterMyTargetUtils.logEnabled) {                             \
    NSLog(@"[%@ error] %@", NSStringFromClass([self class]), (message)); \
  }

/// Sets |value| for |key| in |dictionary| if |value| is not nil.
void GADMAdapterMyTargetMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                         id<NSCopying> _Nullable key,
                                                         id _Nullable value);

/// Returns an SDK specific NSError with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterMyTargetSDKErrorWithDescription(NSString *_Nonnull description);

/// Returns an adapter specific NSError with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterMyTargetAdapterErrorWithDescription(NSString *_Nonnull description);

/// Sets myTarget's customParams from |connector|.
void GADMAdapterMyTargetFillCustomParams(MTRGCustomParams *_Nonnull customParams,
                                         id<GADMAdNetworkConnector> _Nonnull connector);

/// Gets the myTarget slot ID from the specified |credentials|.
NSUInteger GADMAdapterMyTargetSlotIdFromCredentials(
    NSDictionary<NSString *, id> *_Nullable credentials);

/// Returns a GADNativeAdImage from the specified myTarget |imageData|.
GADNativeAdImage *_Nullable GADMAdapterMyTargetNativeAdImageWithImageData(
    MTRGImageData *_Nullable imageData);

@interface GADMAdapterMyTargetUtils : NSObject

/// Indicates whether debug logs are enabled for the myTarget adapter.
@property(class, nonatomic, assign) BOOL logEnabled;

@end
