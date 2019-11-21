//
//  GADMAdapterVungleUtils.h
//  Copyright © 2019 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VungleSDK/VungleSDK.h>
#import "VungleAdNetworkExtras.h"

/// Safely adds |object| to |set| if |object| is not nil.
void GADMAdapterVungleMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

/// Safely sets |value| for |key| in mapTable if |value| is not nil.
void GADMAdapterVungleMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                              id<NSCopying> _Nullable key, id _Nullable value);

/// Safely removes the |object| for |key| in mapTable if |key| is not nil.
void GADMAdapterVungleMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable, id _Nullable key);

NS_ASSUME_NONNULL_BEGIN

@interface GADMAdapterVungleUtils : NSObject

+ (NSString *)findAppID:(NSDictionary *)serverParameters;
+ (NSString *)findPlacement:(NSDictionary *)serverParameters
              networkExtras:(VungleAdNetworkExtras *)networkExtras;

@end

NS_ASSUME_NONNULL_END
