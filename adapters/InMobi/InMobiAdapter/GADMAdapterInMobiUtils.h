//
//  GADMAdapterInMobiUtils.h
//  Adapter
//  Copyright © 2019 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NSInteger GADMAdapterInMobiAdMobErrorCodeForInMobiCode(NSInteger inMobiErrorCode);

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

/// Returns an NSError with the specified |code| and |description|.
NSError *_Nonnull GADMAdapterInMobiErrorWithCodeAndDescription(NSInteger code,
                                                               NSString *_Nonnull description);

/// Validates the placement identifier obtained from the Google Mobile Ads SDK.
NSError *_Nullable GADMAdapterInMobiValidatePlacementIdentifier(
    NSNumber *_Nonnull placementIdentifier);
