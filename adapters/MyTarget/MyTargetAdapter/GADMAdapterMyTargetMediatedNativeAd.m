//
//  GADMAdapterMyTargetMediatedNativeAd.m
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 29.09.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

#import "GADMAdapterMyTargetMediatedNativeAd.h"

#define guard(CONDITION) if (CONDITION) {}

@interface GADMAdapterMyTargetMediatedNativeAd ()

+ (nullable GADNativeAdImage *)nativeAdImageWithImageData:(MTRGImageData *)imageData;

@end

@interface GADMAdapterMyTargetMediatedNativeContentAd : NSObject <GADMediatedNativeContentAd>

@end

@implementation GADMAdapterMyTargetMediatedNativeContentAd
{
	__weak id<GADMediatedNativeAdDelegate> _delegate;
	NSString *_headline;
	NSString *_body;
	NSArray<GADNativeAdImage *> *_images;
	GADNativeAdImage *_logo;
	NSString *_callToAction;
	NSString *_advertiser;
}

- (instancetype)initWithPromoBanner:(MTRGNativePromoBanner *)promoBanner delegate:(id<GADMediatedNativeAdDelegate>)delegate
{
	self = [super init];
	if (self)
	{
		_delegate = delegate;
		if (promoBanner)
		{
			_headline = promoBanner.title;
			_body = promoBanner.descriptionText;
			_callToAction = promoBanner.ctaText;
			_advertiser = promoBanner.advertisingLabel;
			_logo = [GADMAdapterMyTargetMediatedNativeAd nativeAdImageWithImageData:promoBanner.icon];

			GADNativeAdImage *image = [GADMAdapterMyTargetMediatedNativeAd nativeAdImageWithImageData:promoBanner.image];
			_images = (image != nil) ? @[image] : nil;
		}
	}
	return self;
}

- (id<GADMediatedNativeAdDelegate>)mediatedNativeAdDelegate
{
	return _delegate;
}

- (NSDictionary *)extraAssets
{
	return nil;
}

- (NSString *)headline
{
	return _headline;
}

- (NSString *)body
{
	return _body;
}

- (NSArray *)images
{
	return _images;
}

- (GADNativeAdImage *)logo
{
	return _logo;
}

- (NSString *)callToAction
{
	return _callToAction;
}

- (NSString *)advertiser
{
	return _advertiser;
}

- (UIView *)adChoicesView
{
	return nil;
}

@end

@interface GADMAdapterMyTargetMediatedNativeAppInstallAd : NSObject <GADMediatedNativeAppInstallAd>

@end

@implementation GADMAdapterMyTargetMediatedNativeAppInstallAd
{
	__weak id<GADMediatedNativeAdDelegate> _delegate;
	NSString *_headline;
	NSString *_body;
	NSArray<GADNativeAdImage *> *_images;
	GADNativeAdImage *_icon;
	NSString *_callToAction;
	NSDecimalNumber *_starRating;
}

- (instancetype)initWithPromoBanner:(MTRGNativePromoBanner *)promoBanner delegate:(id<GADMediatedNativeAdDelegate>)delegate
{
	self = [super init];
	if (self)
	{
		_delegate = delegate;
		if (promoBanner)
		{
			_headline = promoBanner.title;
			_body = promoBanner.descriptionText;
			_callToAction = promoBanner.ctaText;
			_starRating = [NSDecimalNumber decimalNumberWithDecimal:promoBanner.rating.decimalValue];
			_icon = [GADMAdapterMyTargetMediatedNativeAd nativeAdImageWithImageData:promoBanner.icon];

			GADNativeAdImage *image = [GADMAdapterMyTargetMediatedNativeAd nativeAdImageWithImageData:promoBanner.image];
			_images = (image != nil) ? @[image] : nil;
		}
	}
	return self;
}

- (id<GADMediatedNativeAdDelegate>)mediatedNativeAdDelegate
{
	return _delegate;
}

- (NSDictionary *)extraAssets
{
	return nil;
}

- (NSString *)headline
{
	return _headline;
}

- (NSArray *)images
{
	return _images;
}

- (NSString *)body
{
	return _body;
}

- (GADNativeAdImage *)icon
{
	return _icon;
}

- (NSString *)callToAction
{
	return _callToAction;
}

- (NSDecimalNumber *)starRating
{
	return _starRating;
}

- (NSString *)store
{
	return nil;
}

- (NSString *)price
{
	return nil;
}

- (UIView *)adChoicesView
{
	return nil;
}

@end

@implementation GADMAdapterMyTargetMediatedNativeAd

+ (id<GADMediatedNativeAd>)mediatedNativeAdWithNativePromoBanner:(MTRGNativePromoBanner *)promoBanner delegate:(id<GADMediatedNativeAdDelegate>)delegate
{
	if (promoBanner.navigationType == MTRGNavigationTypeWeb)
	{
		GADMAdapterMyTargetMediatedNativeContentAd *mediatedNativeContentAd = [[GADMAdapterMyTargetMediatedNativeContentAd alloc] initWithPromoBanner:promoBanner delegate:delegate];
		return mediatedNativeContentAd;
	}
	else if (promoBanner.navigationType == MTRGNavigationTypeStore)
	{
		GADMAdapterMyTargetMediatedNativeAppInstallAd *mediatedNativeAppInstallAd = [[GADMAdapterMyTargetMediatedNativeAppInstallAd alloc] initWithPromoBanner:promoBanner delegate:delegate];
		return mediatedNativeAppInstallAd;
	}
	return nil;
}

+ (GADNativeAdImage *)nativeAdImageWithImageData:(MTRGImageData *)imageData
{
	guard(imageData) else return nil;

	GADNativeAdImage *nativeAdImage = nil;
	if (imageData.image)
	{
		nativeAdImage = [[GADNativeAdImage alloc] initWithImage:imageData.image];
	}
	else if (imageData.url)
	{
		NSURL *url = [NSURL URLWithString:imageData.url];
		nativeAdImage = [[GADNativeAdImage alloc] initWithURL:url scale:1.0];
	}
	return nativeAdImage;
}

@end
