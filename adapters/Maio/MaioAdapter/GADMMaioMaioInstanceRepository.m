//
//  GADMMaioMaioInstanceRepository.m
//  GADMMaioAdapter
//
//  Copyright © 2017 i-mobile, Inc. All rights reserved.
//

#import "GADMMaioMaioInstanceRepository.h"

@implementation GADMMaioMaioInstanceRepository

static MaioInstance *_maioInstance = nil;

/// YES if maio SDK is initialized.
static BOOL _isInitialized = NO;


- (MaioInstance *)maioInstanceByMediaId:(NSString *)mediaId {
    return _maioInstance;
}

- (void)addMaioInstance:(MaioInstance *)instance {
    _maioInstance = instance;
}

- (BOOL)isInitializedWithMediaId:(NSString *)mediaId {
    return _isInitialized;
}

- (void)setInitialized:(BOOL)value mediaId:(NSString *)mediaId {
    _isInitialized = value;
}

@end
