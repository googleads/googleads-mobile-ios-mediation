//
//  GADMediationAdapterFyber.m
//  Adapter
//
//  Created by Fyber on 8/8/19.
//  Copyright © 2019 Google. All rights reserved.
//


#import "GADMediationAdapterFyber.h"
#import "GADFYBMediationRewardedAd.h"
#import "GADMAdapterFyberConstants.h"

@import CoreLocation;
@import GoogleMobileAds;
@import IASDKCore;
@import IASDKVideo;
@import IASDKMRAID;

@interface GADMediationAdapterFyber () <GADMediationAdapter, GADMAdNetworkAdapter, IAUnitDelegate>

@property (nonatomic, nonnull) id<GADMAdNetworkConnector> connector;

@property (nonatomic, strong, nonnull) IAViewUnitController *viewUnitController;
@property (nonatomic, strong, nonnull) IAFullscreenUnitController *fullscreenUnitController;

@property (nonatomic, strong, nonnull) IAMRAIDContentController *MRAIDContentController;
@property (nonatomic, strong, nonnull) IAVideoContentController *videoContentController;

@property (nonatomic, strong) IAAdSpot *adSpot;

@property (nonatomic, strong, nullable) GADFYBMediationRewardedAd *rewardedAd;

@end

@implementation GADMediationAdapterFyber

#pragma mark - GADMediationAdapter

+ (GADVersionNumber)adSDKVersion {
    return [GADMediationAdapterFyber versionFromString:[[IASDKCore sharedInstance] version]];
}


+ (GADVersionNumber)version {
    return [GADMediationAdapterFyber versionFromString:kFYBAdapterVersion];
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {

    if (configuration.credentials.count > 0) {
        GADMediationCredentials *credentials = configuration.credentials[0];
        NSString *applicationId = credentials.settings[@"applicationId"];
        
        if (applicationId) {
            NSLog(@"Fyber marketplace SDK version: %@", IASDKCore.sharedInstance.version);
            [IALogger setLogLevel:IALogLevelVerbose];
            dispatch_async(dispatch_get_main_queue(), ^{
                [IASDKCore.sharedInstance initWithAppID:applicationId];
                completionHandler(nil);
            });
        } else {
            completionHandler([NSError errorWithDomain:kGADMAdapterFyberErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:@"Fyber marketplace could not initialized, app ID is unknown"}]);
        }
    }
}

#pragma mark - GADMAdNetworkAdapter

+ (NSString *)adapterVersion {
    return kFYBAdapterVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return nil;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
    self = [super init];
    
    if (self) {
        _connector = connector;
    }
    
    return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
    __weak typeof(self) weakSelf = self;
    NSString *spotId = [self.connector credentials][kFYBSpotID];
    
    [self initBannerWithRequest:[self buildRequestWithSpotId:spotId]];
    [self.adSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) {
        __strong typeof(self) strongSelf = weakSelf;

        if (error) {
            [strongSelf.connector adapter:strongSelf didFailAd:error];
        } else {
            [strongSelf.connector adapter:strongSelf didReceiveAdView:strongSelf.viewUnitController.adView];
        }
    }];
}

- (void)getInterstitial {
    __weak typeof(self) weakSelf = self;
    NSString *spotId = [self.connector credentials][kFYBSpotID];
    
    [self initInterstitialWithRequest:[self buildRequestWithSpotId:spotId]];
    [self.adSpot fetchAdWithCompletion:^(IAAdSpot * _Nullable adSpot, IAAdModel * _Nullable adModel, NSError * _Nullable error) {
        __strong typeof(self) strongSelf = weakSelf;

        if (error) {
            [strongSelf.connector adapter:strongSelf didFailAd:error];
        } else {
            [strongSelf.connector adapterDidReceiveInterstitial:strongSelf];
        }
    }];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
    _rewardedAd = [[GADFYBMediationRewardedAd alloc] init];
    [self.rewardedAd loadRewardedAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)stopBeingDelegate {
    if (self.viewUnitController.unitDelegate) {
        self.viewUnitController.unitDelegate = nil;
    }
    
    if (self.fullscreenUnitController.unitDelegate) {
        self.fullscreenUnitController.unitDelegate = nil;
    }
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
    [self.fullscreenUnitController showAdAnimated:YES completion:nil];
}

#pragma mark - Service

- (IAAdRequest * _Nonnull)buildRequestWithSpotId:(NSString *)spotId {
    IAAdRequest *request = [IAAdRequest build:^(id<IAAdRequestBuilder>  _Nonnull builder) {
        builder.useSecureConnections = NO;
        builder.spotID = spotId;
        builder.timeout = 10;
        builder.keywords = [[self.connector.userKeywords valueForKey:@"description"] componentsJoinedByString:@""];
        
        if ([self.connector userHasLocation]) {
            builder.location = [[CLLocation alloc] initWithLatitude:self.connector.userLatitude longitude:self.connector.userLongitude];
        }
    }];
    
    return request;
}

- (void)initBannerWithRequest:(IAAdRequest * _Nonnull)request {
    _MRAIDContentController = [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder>  _Nonnull builder) {}];
    
    _viewUnitController = [IAViewUnitController build:^(id<IAViewUnitControllerBuilder>  _Nonnull builder) {
        builder.unitDelegate = self;
        [builder addSupportedContentController:self.MRAIDContentController];
    }];
    
    _adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder>  _Nonnull builder) {
        builder.adRequest = request;
        [builder addSupportedUnitController:self.viewUnitController];
    }];
}

- (void)initInterstitialWithRequest:(IAAdRequest * _Nonnull)request {
    _MRAIDContentController = [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder>  _Nonnull builder) {}];
    _videoContentController = [IAVideoContentController build:^(id<IAVideoContentControllerBuilder>  _Nonnull builder) {}];

    _fullscreenUnitController = [IAFullscreenUnitController build:^(id<IAFullscreenUnitControllerBuilder>  _Nonnull builder) {
        builder.unitDelegate = self;
        [builder addSupportedContentController:self.MRAIDContentController];
        [builder addSupportedContentController:self.videoContentController];
    }];

    _adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder>  _Nonnull builder) {
        builder.adRequest = request;
        [builder addSupportedUnitController:self.fullscreenUnitController];
    }];
}

+ (GADVersionNumber)versionFromString:(NSString *)versionString {
    NSArray <NSString *> *versionAsArray = [versionString componentsSeparatedByString:@"."];
    GADVersionNumber version = {0};
    
    if (versionAsArray.count == 3) {
        version.majorVersion = versionAsArray[0].integerValue;
        version.minorVersion = versionAsArray[1].integerValue;
        version.patchVersion = versionAsArray[2].integerValue;
    }
    return version;
}

#pragma mark - IAUnitDelegate

- (UIViewController * _Nonnull)IAParentViewControllerForUnitController:(IAUnitController * _Nullable)unitController {
    return [self.connector viewControllerForPresentingModalView];
}

- (void)IAAdDidReceiveClick:(IAUnitController * _Nullable)unitController {
    [self.connector adapterDidGetAdClick:self];
}

- (void)IAUnitControllerWillPresentFullscreen:(IAUnitController * _Nullable)unitController {
    if (unitController == self.viewUnitController) {
        [self.connector adapterWillPresentFullScreenModal:self];
    } else if (unitController == self.fullscreenUnitController) {
        [self.connector adapterWillPresentInterstitial:self];
    }
}

- (void)IAUnitControllerWillDismissFullscreen:(IAUnitController * _Nullable)unitController {
    if (unitController == self.viewUnitController) {
        [self.connector adapterWillDismissFullScreenModal:self];
    } else if (unitController == self.fullscreenUnitController) {
        [self.connector adapterWillDismissInterstitial:self];
    }
}

- (void)IAUnitControllerDidDismissFullscreen:(IAUnitController * _Nullable)unitController {
    if (unitController == self.viewUnitController) {
        [self.connector adapterDidDismissFullScreenModal:self];
    } else if (unitController == self.fullscreenUnitController) {
        [self.connector adapterDidDismissInterstitial:self];
    }
}

- (void)IAUnitControllerWillOpenExternalApp:(IAUnitController * _Nullable)unitController {
    [self.connector adapterWillLeaveApplication:self];
}

@end
