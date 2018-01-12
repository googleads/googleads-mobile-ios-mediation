//
//  GADMAdapterAppLovinConstant.h
//
//
//  Created by Thomas So on 1/11/18.
//
//

#import <Foundation/Foundation.h>

@interface GADMAdapterAppLovinConstant : NSObject

@property (class, nonatomic, copy, readonly) NSString *errorDomain;
@property (class, nonatomic, copy, readonly) NSString *adapterVersion;

@property (class, nonatomic, copy, readonly) NSString *sdkKey;
@property (class, nonatomic, copy, readonly) NSString *placementKey;
@property (class, nonatomic, copy, readonly) NSString *bundleIdentifierKey;

@property (class, nonatomic, assign, readonly) BOOL loggingEnabled;

@end
