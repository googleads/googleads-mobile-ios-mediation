//
//  Copyright © 2018 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AdColony/AdColony.h>
@import GoogleMobileAds;

@interface GADMediationAdapterAdColony : NSObject <GADRTBAdapter>

@property (class, nonatomic, strong, readonly) AdColonyAppOptions *appOptions;

@end
