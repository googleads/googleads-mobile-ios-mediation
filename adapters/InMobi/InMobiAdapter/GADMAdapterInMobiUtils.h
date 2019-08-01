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

void GADMAdapterInMobiMutableSetSafeGADRTBSignalCompletionHandler(
    GADRTBSignalCompletionHandler handler, GADRTBSignalCompletionHandler setHandler);
