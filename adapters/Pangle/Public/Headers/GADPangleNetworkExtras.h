//
//  GADPangleNetworkExtras.h
//  Adapter
//
//  Created by bytedance on 2022/6/23.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

@interface GADPangleNetworkExtras : NSObject <GADAdNetworkExtras>

@property (nonatomic, copy) NSString *userDataString;

@end

NS_ASSUME_NONNULL_END
