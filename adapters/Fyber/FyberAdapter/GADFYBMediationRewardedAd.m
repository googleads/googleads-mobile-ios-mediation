//
//  GADFYBMediationRewardedAd.m
//  Adapter
//
//  Created by Fyber on 9/9/19.
//  Copyright © 2019 Google. All rights reserved.
//

#import "GADFYBMediationRewardedAd.h"
#import "GADMAdapterFyberConstants.h"

@import IASDKCore;
@import IASDKVideo;
@import CoreLocation;

@interface GADFYBMediationRewardedAd () <GADMediationRewardedAd, IAUnitDelegate, IAVideoContentDelegate>

@property (nonatomic, strong, nonnull) IAFullscreenUnitController *fullscreenUnitController;
@property (nonatomic, strong, nonnull) IAVideoContentController *videoContentController;
@property (nonatomic, strong) IAAdSpot *adSpot;

@property (nonatomic, weak) UIViewController *parentViewController;

@property(nonatomic, copy) GADMediationRewardedLoadCompletionHandler loadCompletionHandler;
@property(nonatomic, weak) id<GADMediationRewardedAdEventDelegate> delegate;

@end

@implementation GADFYBMediationRewardedAd

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        _loadCompletionHandler = nil;
        _delegate = nil;
    }
    return self;
}

#pragma mark - API

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
    NSString *spotId = adConfiguration.credentials.settings[kFYBSpotID];

    _loadCompletionHandler = completionHandler;
    
    IAAdRequest *request = [IAAdRequest build:^(id<IAAdRequestBuilder>  _Nonnull builder) {
        builder.useSecureConnections = NO;
        builder.spotID = spotId;
        builder.timeout = 10;
        
        if ([adConfiguration hasUserLocation]) {
            builder.location = [[CLLocation alloc] initWithLatitude:adConfiguration.userLatitude longitude:adConfiguration.userLongitude];
        }
    }];
    
    _videoContentController = [IAVideoContentController build:^(id<IAVideoContentControllerBuilder>  _Nonnull builder) {
        builder.videoContentDelegate = self;
    }];
    
    _fullscreenUnitController = [IAFullscreenUnitController build:^(id<IAFullscreenUnitControllerBuilder>  _Nonnull builder) {
        builder.unitDelegate = self;
        [builder addSupportedContentController:self.videoContentController];
    }];
    
    _adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder>  _Nonnull builder) {
        builder.adRequest = request;
        [builder addSupportedUnitController:self.fullscreenUnitController];
    }];
    __weak typeof(self) weakSelf = self;

    [self.adSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) {
        __strong typeof(self) strongSelf = weakSelf;

        if (error) {
            completionHandler(nil, error);
        } else {
            if (completionHandler) {
                strongSelf.delegate = completionHandler(strongSelf, nil);
            }
        }
    }];
}

#pragma mark - GADMediationRewardedAd

- (void)presentFromViewController:(UIViewController *)viewController {
    _parentViewController = viewController;
    [self.fullscreenUnitController showAdAnimated:YES completion:nil];
}

#pragma mark - IAUnitDelegate

- (UIViewController * _Nonnull)IAParentViewControllerForUnitController:(IAUnitController * _Nullable)unitController {
    return self.parentViewController;
}

- (void)IAAdDidReceiveClick:(IAUnitController * _Nullable)unitController {
    [self.delegate reportClick];
}

- (void)IAAdWillLogImpression:(IAUnitController * _Nullable)unitController {
    [self.delegate reportImpression];
}

- (void)IAUnitControllerWillPresentFullscreen:(IAUnitController * _Nullable)unitController {
    [self.delegate willPresentFullScreenView];
}

- (void)IAUnitControllerWillDismissFullscreen:(IAUnitController * _Nullable)unitController {
    [self.delegate willDismissFullScreenView];
}

- (void)IAUnitControllerDidDismissFullscreen:(IAUnitController * _Nullable)unitController {
    [self.delegate didDismissFullScreenView];
}

#pragma mark - IAVideoContentDelegate

- (void)IAVideoCompleted:(IAVideoContentController * _Nullable)contentController {
    id<GADMediationRewardedAdEventDelegate> strongDelegate = self.delegate;
    GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:@"" rewardAmount:[NSDecimalNumber decimalNumberWithString:@"1"]];
    
    [strongDelegate didEndVideo];
    [strongDelegate didRewardUserWithReward:reward];
}

- (void)IAVideoContentController:(IAVideoContentController *)contentController videoInterruptedWithError:(NSError *)error {
    [self.delegate didFailToPresentWithError:error];
}

- (void)IAVideoContentController:(IAVideoContentController * _Nullable)contentController videoProgressUpdatedWithCurrentTime:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime {
    if (currentTime == 0) {
        [self.delegate didStartVideo];
    }
}

@end
