//
//  GADMAdapterNendUtils.h
//  NendAdapter
//
//  Copyright © 2018 F@N Communications. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NADUserFeature;
@protocol GADMediationAdRequest;

@interface GADMAdapterNendUtils : NSObject

+ (NADUserFeature *)getUserFeatureFromMediationRequest:(id<GADMediationAdRequest>)request;

@end
