//
//  GADMAdapterMyTargetNative.m
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 29.09.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

@import MyTargetSDK;

#import "GADMAdapterMyTargetNative.h"
#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetUtils.h"
#import "GADMAdapterMyTargetMediatedNativeAd.h"
#import "GADMAdapterMyTargetExtras.h"

#define guard(CONDITION) if (CONDITION) {}

@interface GADMAdapterMyTargetNative () <MTRGNativeAdDelegate, GADMediatedNativeAdDelegate>

@end

@implementation GADMAdapterMyTargetNative
{
	MTRGNativeAd *_nativeAd;
	id<GADMediatedNativeAd> _mediatedNativeAd;
	__weak id<GADMAdNetworkConnector> _connector;
	BOOL _isContentAdRequested;
	BOOL _isAppInstallAdRequested;
	NSString *_adTypesRequested;
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
			[GADMAdapterMyTargetUtils setLogEnabled:extras.isDebugMode];
		}

		MTRGLogInfo();
		MTRGLogDebug(@"Credentials: %@", connector.credentials);
		_connector = connector;
	}
	return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	MTRGLogInfo();
	guard(strongConnector) else return;
	[strongConnector adapter:self didFailAd:[GADMAdapterMyTargetUtils errorWithDescription:kGADMAdapterMyTargetErrorBannersNotSupported]];
}

- (void)getInterstitial
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	MTRGLogInfo();
	guard(strongConnector) else return;
	[strongConnector adapter:self didFailAd:[GADMAdapterMyTargetUtils errorWithDescription:kGADMAdapterMyTargetErrorInterstitialNotSupported]];
}

- (void)stopBeingDelegate
{
	MTRGLogInfo();
	_connector = nil;
	if (_nativeAd)
	{
		_nativeAd.delegate = nil;
		_nativeAd = nil;
	}
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType
{
	return YES;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	MTRGLogInfo();
	guard(strongConnector) else return;
	[strongConnector adapter:self didFailAd:[GADMAdapterMyTargetUtils errorWithDescription:kGADMAdapterMyTargetErrorInterstitialNotSupported]];
}

- (void)getNativeAdWithAdTypes:(NSArray *)adTypes options:(NSArray *)options
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	MTRGLogInfo();
	guard(strongConnector) else return;

	NSUInteger slotId = [GADMAdapterMyTargetUtils slotIdFromCredentials:strongConnector.credentials];
	guard(slotId > 0) else
	{
		MTRGLogError(kGADMAdapterMyTargetErrorSlotId);
		[strongConnector adapter:self didFailAd:[GADMAdapterMyTargetUtils errorWithDescription:kGADMAdapterMyTargetErrorSlotId]];
		return;
	}
	
	_isContentAdRequested = [adTypes containsObject:kGADAdLoaderAdTypeNativeContent];
	_isAppInstallAdRequested = [adTypes containsObject:kGADAdLoaderAdTypeNativeAppInstall];
	_adTypesRequested = [adTypes componentsJoinedByString:@", "];

	guard(_isContentAdRequested || _isAppInstallAdRequested) else
	{
		NSString *description = [NSString stringWithFormat:kGADMAdapterMyTargetErrorInvalidNativeAdType, _adTypesRequested];
		MTRGLogError(description);
		[strongConnector adapter:self didFailAd:[GADMAdapterMyTargetUtils errorWithDescription:description]];
		return;
	}

	BOOL shouldDownloadImages = YES;
	for (GADNativeAdImageAdLoaderOptions *imageOptions in options)
	{
		if ([imageOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]] && imageOptions.disableImageLoading)
		{
			shouldDownloadImages = NO;
			break;
		}
	}

	_nativeAd = [[MTRGNativeAd alloc] initWithSlotId:slotId];
	_nativeAd.delegate = self;
	_nativeAd.autoLoadImages = shouldDownloadImages;
	[GADMAdapterMyTargetUtils fillCustomParams:_nativeAd.customParams withConnector:strongConnector];
	[_nativeAd.customParams setCustomParam:kMTRGCustomParamsMediationAdmob forKey:kMTRGCustomParamsMediationKey];

	if (_isContentAdRequested && !_isAppInstallAdRequested)
	{
		[_nativeAd.customParams setCustomParam:kGADMAdapterMyTargetNativeAdTypeContent forKey:kGADMAdapterMyTargetNativeAdTypeKey];
	}
	else if (_isAppInstallAdRequested && !_isContentAdRequested)
	{
		[_nativeAd.customParams setCustomParam:kGADMAdapterMyTargetNativeAdTypeInstall forKey:kGADMAdapterMyTargetNativeAdTypeKey];
	}
	[_nativeAd load];
}

- (BOOL)handlesUserClicks
{
	return YES;
}

- (BOOL)handlesUserImpressions
{
	return YES;
}

#pragma mark - MTRGNativeAdDelegate

- (void)onLoadWithNativePromoBanner:(MTRGNativePromoBanner *)promoBanner nativeAd:(MTRGNativeAd *)nativeAd
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	MTRGLogInfo();
	guard(strongConnector) else return;

	_mediatedNativeAd = [GADMAdapterMyTargetMediatedNativeAd mediatedNativeAdWithNativePromoBanner:promoBanner delegate:self];
	guard(_mediatedNativeAd) else
	{
		MTRGLogError(kGADMAdapterMyTargetErrorMediatedAdInvalid);
		[strongConnector adapter:self didFailAd:[GADMAdapterMyTargetUtils errorWithDescription:kGADMAdapterMyTargetErrorMediatedAdInvalid]];
		return;
	}
	Class mediatedNativeAdClass = _mediatedNativeAd.class;
	guard(_isContentAdRequested && [mediatedNativeAdClass conformsToProtocol:@protocol(GADMediatedNativeContentAd)] ||
		  _isAppInstallAdRequested && [mediatedNativeAdClass conformsToProtocol:@protocol(GADMediatedNativeAppInstallAd)]) else
	{
		NSString *description = [NSString stringWithFormat:kGADMAdapterMyTargetErrorMediatedAdDoesNotMatch, NSStringFromClass(mediatedNativeAdClass), _adTypesRequested];
		MTRGLogError(description);
		[strongConnector adapter:self didFailAd:[GADMAdapterMyTargetUtils errorWithDescription:description]];
		return;
	}
	[strongConnector adapter:self didReceiveMediatedNativeAd:_mediatedNativeAd];
}

- (void)onNoAdWithReason:(NSString *)reason nativeAd:(MTRGNativeAd *)nativeAd
{
	id<GADMAdNetworkConnector> strongConnector = _connector;
	NSString *description = [GADMAdapterMyTargetUtils noAdWithReason:reason];
	MTRGLogError(description);
	guard(strongConnector) else return;
	NSError *error = [GADMAdapterMyTargetUtils errorWithDescription:description];
	[strongConnector adapter:self didFailAd:error];
}

- (void)onAdShowWithNativeAd:(MTRGNativeAd *)nativeAd
{
	MTRGLogInfo();
	guard(_mediatedNativeAd) else return;
	[GADMediatedNativeAdNotificationSource mediatedNativeAdDidRecordImpression:_mediatedNativeAd];
}

- (void)onAdClickWithNativeAd:(MTRGNativeAd *)nativeAd
{
	MTRGLogInfo();
	guard(_mediatedNativeAd) else return;
	[GADMediatedNativeAdNotificationSource mediatedNativeAdDidRecordClick:_mediatedNativeAd];
}

- (void)onShowModalWithNativeAd:(MTRGNativeAd *)nativeAd
{
	MTRGLogInfo();
	guard(_mediatedNativeAd) else return;
	[GADMediatedNativeAdNotificationSource mediatedNativeAdWillPresentScreen:_mediatedNativeAd];
}

- (void)onDismissModalWithNativeAd:(MTRGNativeAd *)nativeAd
{
	MTRGLogInfo();
	guard(_mediatedNativeAd) else return;
	[GADMediatedNativeAdNotificationSource mediatedNativeAdWillDismissScreen:_mediatedNativeAd];
	[GADMediatedNativeAdNotificationSource mediatedNativeAdDidDismissScreen:_mediatedNativeAd];
}

- (void)onLeaveApplicationWithNativeAd:(MTRGNativeAd *)nativeAd
{
	MTRGLogInfo();
	guard(_mediatedNativeAd) else return;
	[GADMediatedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:_mediatedNativeAd];
}

#pragma mark - GADMediatedNativeAdDelegate

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd didRenderInView:(UIView *)view viewController:(UIViewController *)viewController
{
	MTRGLogInfo();
	guard(_nativeAd) else return;
	[_nativeAd registerView:view withController:viewController];
}

- (void)mediatedNativeAdDidRecordImpression:(id<GADMediatedNativeAd>)mediatedNativeAd
{
	// do nothing
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd didRecordClickOnAssetWithName:(NSString *)assetName view:(UIView *)view viewController:(UIViewController *)viewController
{
	// do nothing
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd didUntrackView:(UIView *)view
{
	MTRGLogInfo();
	guard(_nativeAd) else return;
	[_nativeAd unregisterView];
}

@end
