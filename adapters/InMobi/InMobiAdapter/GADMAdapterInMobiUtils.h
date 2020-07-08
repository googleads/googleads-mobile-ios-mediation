//
//  GADMAdapterInMobiUtils.h
//  Adapter
//  Copyright © 2019 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "GADMediationAdapterInMobi.h"

/// Adds |object| to |array| if |object| is not nil.
void GADMAdapterInMobiMutableArrayAddObject(NSMutableArray *_Nullable array,
                                            NSObject *_Nonnull object);

/// Adds |object| to |set| if |object| is not nil.
void GADMAdapterInMobiMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

/// Sets |value| for |key| in mapTable if |key| and |value| are not nil.
void GADMAdapterInMobiMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                              id<NSCopying> _Nullable key, id _Nullable value);

/// Removes the object for |key| in mapTable if |key| is not nil.
void GADMAdapterInMobiMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable, id _Nullable key);

/// Sets |value| for |key| in |dictionary| if |key| and |value| are not nil.
void GADMAdapterInMobiMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                       id<NSCopying> _Nullable key,
                                                       id _Nullable value);

/// Sets |value| for |key| in |cache| if |key| and |value| are not nil.
void GADMAdapterInMobiCacheSetObjectForKey(NSCache *_Nonnull cache, id<NSCopying> _Nullable key,
                                           id _Nullable value);

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterInMobiErrorWithCodeAndDescription(GADMAdapterInMobiErrorCode code,
                                                               NSString *_Nonnull description);

/// Validates the placement identifier obtained from the Google Mobile Ads SDK.
NSError *_Nullable GADMAdapterInMobiValidatePlacementIdentifier(
    NSNumber *_Nonnull placementIdentifier);

/// Sets up InMobi targetting information from the specified |connector|.
void GADMAdapterInMobiSetTargetingFromConnector(id<GADMAdNetworkConnector> _Nonnull connector);

/// Sets up InMobi targetting information from the specified ad configuration.
void GADMAdapterInMobiSetTargetingFromAdConfiguration(
    GADMediationAdConfiguration *_Nonnull adConfig);

/// Creates InMobi request parameters from the specified |connector|.
NSDictionary<NSString *, id> *_Nonnull GADMAdapterInMobiCreateRequestParametersFromConnector(
    id<GADMAdNetworkConnector> _Nonnull connector);

/// Creates InMobi request parameters from the specified ad configuration.
NSDictionary<NSString *, id> *_Nonnull GADMAdapterInMobiCreateRequestParametersFromAdConfiguration(
    GADMediationAdConfiguration *_Nonnull adConfig);
