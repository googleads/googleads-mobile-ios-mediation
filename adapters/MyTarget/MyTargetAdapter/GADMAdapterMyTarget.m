//
//  GADMAdapterMyTarget.m
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 27.09.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

@import MyTargetSDK;

#import "GADMAdapterMyTarget.h"
#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetUtils.h"
#import "GADMAdapterMyTargetExtras.h"

#define guard(CONDITION) if (CONDITION) {}

@interface GADMAdapterMyTarget() <MTRGAdViewDelegate, MTRGInterstitialAdDelegate>

@end

@implementation GADMAdapterMyTarget
{
	MTRGAdView *_adView;
	MTRGInterstitialAd *_interstitialAd;
	__weak id<GADMAdNetworkConnector> _connector;
	BOOL _isInterstitialAllowed;
	BOOL _isInterstitialStarted;
}

+ (NSString *)adapterVersion
{
	return kGADMAdapterMyTargetVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass
{
	return [GADMAdapterMyTargetExtras class];
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector
{
	self = [super init];
	if (self)
	{
		id<GADAdNetworkExtras> networkExtras = connector.networkExtras;
		if (networkExtras && [networkExtras isKindOfClass:[GADMAdapterMyTargetExtras class]])
		{
			GADMAdapterMyTargetExtras *extras = (GADMAdapterMyTargetExtras *)networkExtras;
			[GADMAdapterMyTargetLogger setEnabled:extras.isDebugMode];
		}

		[self logDebug:NSStringFromSelector(_cmd)];
		[self logDebug:[NSString stringWithFormat:@"Credentials: %@", connector.credentials]];
		_connector = connector;
		_isInterstitialAllowed = NO;
		_isInterstitialStarted = NO;
	}
	return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	[self logDebug:NSStringFromSelector(_cmd)];
	[self logDebug:[NSString stringWithFormat:@"adSize: %.fx%.f", adSize.size.width, adSize.size.height]];
	guard(strongConnector) else return;

	MTRGAdSize adViewSize;
	if ([GADMAdapterMyTargetUtils isSize:adSize equalToSize:kGADAdSizeBanner])
	{
		adViewSize = MTRGAdSize_320x50;
	}
	else if ([GADMAdapterMyTargetUtils isSize:adSize equalToSize:kGADAdSizeMediumRectangle])
	{
		adViewSize = MTRGAdSize_300x250;
	}
	else if ([GADMAdapterMyTargetUtils isSize:adSize equalToSize:kGADAdSizeLeaderboard])
	{
		adViewSize = MTRGAdSize_728x90;
	}
	else
	{
		[self delegateOnNoAdWithReason:kGADMAdapterMyTargetErrorInvalidSize];
		return;
	}

	NSUInteger slotId = [GADMAdapterMyTargetUtils slotIdFromCredentials:strongConnector.credentials];
	guard(slotId > 0) else
	{
		[self logError:kGADMAdapterMyTargetErrorSlotId];
		[strongConnector adapter:self didFailAd:[GADMAdapterMyTargetUtils errorWithDescription:kGADMAdapterMyTargetErrorSlotId]];
		return;
	}

	_adView = [[MTRGAdView alloc] initWithSlotId:slotId withRefreshAd:NO adSize:adViewSize];
	_adView.delegate = self;
	_adView.viewController = strongConnector.viewControllerForPresentingModalView;
	[GADMAdapterMyTargetUtils fillCustomParams:_adView.customParams withConnector:strongConnector];
	[_adView.customParams setCustomParam:kMTRGCustomParamsMediationAdmob forKey:kMTRGCustomParamsMediationKey];
	[_adView load];
}

- (void)getInterstitial
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	[self logDebug:NSStringFromSelector(_cmd)];
	guard(strongConnector) else return;

	NSUInteger slotId = [GADMAdapterMyTargetUtils slotIdFromCredentials:strongConnector.credentials];
	guard(slotId > 0) else
	{
		[self logError:kGADMAdapterMyTargetErrorSlotId];
		[strongConnector adapter:self didFailAd:[GADMAdapterMyTargetUtils errorWithDescription:kGADMAdapterMyTargetErrorSlotId]];
		return;
	}

	_isInterstitialAllowed = NO;
	_interstitialAd = [[MTRGInterstitialAd alloc] initWithSlotId:slotId];
	_interstitialAd.delegate = self;
	[GADMAdapterMyTargetUtils fillCustomParams:_interstitialAd.customParams withConnector:strongConnector];
	[_interstitialAd.customParams setCustomParam:kMTRGCustomParamsMediationAdmob forKey:kMTRGCustomParamsMediationKey];
	[_interstitialAd load];
}

- (void)stopBeingDelegate
{
	[self logDebug:NSStringFromSelector(_cmd)];
	_connector = nil;
	if (_adView)
	{
		_adView.delegate = nil;
		_adView = nil;
	}
	if (_interstitialAd)
	{
		_interstitialAd.delegate = nil;
		_interstitialAd = nil;
	}
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType
{
	return YES;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	[self logDebug:NSStringFromSelector(_cmd)];
	guard(_isInterstitialAllowed && _interstitialAd && strongConnector) else return;

	_isInterstitialStarted = YES;
	[_interstitialAd showWithController:rootViewController];
	[strongConnector adapterWillPresentInterstitial:self];
}

#pragma mark - MTRGAdViewDelegate

- (void)onLoadWithAdView:(MTRGAdView *)adView
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	[self logDebug:NSStringFromSelector(_cmd)];
	guard(strongConnector) else return;
	[adView start];
	[strongConnector adapter:self didReceiveAdView:adView];
}

- (void)onNoAdWithReason:(NSString *)reason adView:(MTRGAdView *)adView
{
	[self delegateOnNoAdWithReason:reason];
}

- (void)onAdClickWithAdView:(MTRGAdView *)adView
{
	[self delegateOnClick];
}

- (void)onShowModalWithAdView:(MTRGAdView *)adView
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	[self logDebug:NSStringFromSelector(_cmd)];
	guard(strongConnector) else return;
	[strongConnector adapterWillPresentFullScreenModal:self];
}

- (void)onDismissModalWithAdView:(MTRGAdView *)adView
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	[self logDebug:NSStringFromSelector(_cmd)];
	guard(strongConnector) else return;
	[strongConnector adapterWillDismissFullScreenModal:self];
	[strongConnector adapterDidDismissFullScreenModal:self];
}

- (void)onLeaveApplicationWithAdView:(MTRGAdView *)adView
{
	[self delegateOnLeaveApplication];
}

#pragma mark - MTRGInterstitialAdDelegate

- (void)onLoadWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	[self logDebug:NSStringFromSelector(_cmd)];
	guard(strongConnector) else return;
	_isInterstitialAllowed = YES;
	[strongConnector adapterDidReceiveInterstitial:self];
}

- (void)onNoAdWithReason:(NSString *)reason interstitialAd:(MTRGInterstitialAd *)interstitialAd
{
	[self delegateOnNoAdWithReason:reason];
}

- (void)onClickWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd
{
	[self delegateOnClick];
}

- (void)onCloseWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	[self logDebug:NSStringFromSelector(_cmd)];
	guard(strongConnector) else return;
	[strongConnector adapterWillDismissInterstitial:self];
	[strongConnector adapterDidDismissInterstitial:self];
}

- (void)onVideoCompleteWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd
{
	// do nothing
}

- (void)onDisplayWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	[self logDebug:NSStringFromSelector(_cmd)];
	guard(strongConnector) else return;
	[strongConnector adapterWillPresentInterstitial:self];
}

- (void)onLeaveApplicationWithInterstitialAd:(MTRGInterstitialAd *)interstitialAd
{
	[self delegateOnLeaveApplication];
}

#pragma mark - delegates

- (void)delegateOnNoAdWithReason:(NSString *)reason
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	NSString *description = [GADMAdapterMyTargetUtils noAdWithReason:reason];
	[self logError:description];
	guard(strongConnector) else return;
	NSError *error = [GADMAdapterMyTargetUtils errorWithDescription:description];
	[strongConnector adapter:self didFailAd:error];
}

- (void)delegateOnClick
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	[self logDebug:NSStringFromSelector(_cmd)];
	guard(strongConnector) else return;
	[strongConnector adapterDidGetAdClick:self];
}

- (void)delegateOnLeaveApplication
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	[self logDebug:NSStringFromSelector(_cmd)];
	guard(strongConnector) else return;
	[strongConnector adapterWillLeaveApplication:self];
}

#pragma mark - helpers

- (void)logDebug:(NSString *)message
{
	gadm_amt_log_d(@"%@ %@", NSStringFromClass([self class]), message);
}

- (void)logError:(NSString *)message
{
	gadm_amt_log_e(@"%@ %@", NSStringFromClass([self class]), message);
}

@end
