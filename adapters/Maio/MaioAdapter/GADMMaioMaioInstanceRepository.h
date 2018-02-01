//
//  GADMMaioMaioInstanceRepository.h
//  GADMMaioAdapter
//
//  Copyright © 2017 i-mobile, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Maio;

@interface GADMMaioMaioInstanceRepository : NSObject

- (MaioInstance *)maioInstanceByMediaId:(NSString *)mediaId;
- (void)addMaioInstance:(MaioInstance *)instance;

- (BOOL)isInitializedWithMediaId:(NSString *)mediaId;
- (void)setInitialized:(BOOL)value mediaId:(NSString *)mediaId;

@end
