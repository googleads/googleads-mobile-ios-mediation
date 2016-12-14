// Copyright (C) 2016 by Tapjoy Inc.
//
// This file is part of the Tapjoy SDK.
//
// By using the Tapjoy SDK in your software, you agree to the terms of the Tapjoy SDK License Agreement.
//
// The Tapjoy SDK is bound by the Tapjoy SDK License Agreement and can be found here: https://www.tapjoy.com/sdk/license

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class TJCustomPlacement;

@protocol TJCustomPlacementDelegate <NSObject>
//TODO: what is ad for?
- (void)customPlacement:(TJCustomPlacement*)customPlacement didLoadAd:(id)ad;
- (void)customPlacement:(TJCustomPlacement*)customPlacement didFailWithError:(NSError*)error;
- (void)customPlacementContentDidAppear:(TJCustomPlacement*)customPlacement;
- (void)customPlacementContentDidDisappear:(TJCustomPlacement*)customPlacement;
- (void)customPlacement:(TJCustomPlacement*)customPlacement shouldReward:(NSString*)type amount:(int)amount;
@end

@interface TJCustomPlacement : NSObject

- (void)requestContentWithCustomPlacementParams:(NSDictionary *)params;
- (void)showContentWithViewController:(UIViewController*)viewController;

@property (nonatomic, weak) id<TJCustomPlacementDelegate> delegate;

@end

