//
//  GADMAdapterInMobiUnifiedNativeAd.m
//  InMobiAdapter
//
//  Created by Niranjan Agrawal on 1/22/16.
//
//

#import "GADMAdapterInMobiUnifiedNativeAd.h"

#import <Foundation/Foundation.h>
#include <stdatomic.h>
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiInitializer.h"
#import "GADMAdapterInMobiUtils.h"
#import "GADMediationAdapterInMobi.h"
#import "NativeAdKeys.h"

static CGFloat const DefaultIconScale = 1.0;

@interface GADMAdapterInMobiUnifiedNativeAd () <IMNativeDelegate>
@end

@implementation GADMAdapterInMobiUnifiedNativeAd {
    id<GADMediationNativeAdEventDelegate> _nativeAdEventDelegate;
    
    /// Ad Configuration for the native ad to be rendered.
    GADMediationNativeAdConfiguration *_nativeAdConfig;
    
    GADMediationNativeLoadCompletionHandler _nativeRenderCompletionHandler;
    
    /// InMobi Placement identifier.
    NSNumber *_placementIdentifier;
    
    /// InMobi native ad object.
    IMNative *_native;
    
    /// Indicates whether native ad images should be downloaded.
    BOOL _shouldDownloadImages;
    
    /// Aspect ratio of the Native ad obtained from InMobi.
    CGFloat _aspectRatio;
    
    /// Icon image sent to Google Mobile Ads SDK.
    GADNativeAdImage *_mappedIcon;
    
    /// Array of GADNativeAdImage objects sent to Google Mobile Ads SDK.
    NSArray<GADNativeAdImage *> *_mappedImages;
    
    /// A dictionary of asset names and object pairs for assets that are not handled by
    /// properties of the GADMediatedUnifiedNativeAd.
    NSDictionary<NSString *, id> *_extras;
    
    /// Contains the assests of the InMobi native ad.
    NSDictionary<NSString *, id> *_nativeAdContentDictionary;
}

static NSCache *imageCache;

__attribute__((constructor)) static void initialize_imageCache() {
    imageCache = [[NSCache alloc] init];
}

- (nonnull instancetype)initWithPlacementIdentifier:(nonnull NSNumber *)placementIdentifier {
    self = [super init];
    if (self) {
        _placementIdentifier = placementIdentifier;
        _shouldDownloadImages = YES;
    }
    return self;
}

- (void)loadNativeAdForAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
    
    _nativeAdConfig = adConfiguration;
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationNativeLoadCompletionHandler originalCompletionHandler =
    [completionHandler copy];
    _nativeRenderCompletionHandler = ^id<GADMediationNativeAdEventDelegate>(id<GADMediationNativeAd> nativeAd, NSError *error) {
        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
            return nil;
        }
        id<GADMediationNativeAdEventDelegate> delegate = nil;
        if (originalCompletionHandler) {
            delegate = originalCompletionHandler(nativeAd, error);
        }
        originalCompletionHandler = nil;
        return delegate;
    };
    
    GADMAdapterInMobiUnifiedNativeAd *__weak weakSelf = self;
    NSString *accountID = _nativeAdConfig.credentials.settings[GADMAdapterInMobiAccountID];
    [GADMAdapterInMobiInitializer.sharedInstance
     initializeWithAccountID:accountID
     completionHandler:^(NSError *_Nullable error) {
        GADMAdapterInMobiUnifiedNativeAd *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        if (error) {
            NSLog(@"[InMobi] Initialization failed: %@", error.localizedDescription);
            strongSelf->_nativeRenderCompletionHandler(nil, error);
            return;
        }
        
        [strongSelf requestNativeAdWithOptions:strongSelf->_nativeAdConfig.options];
    }];
    
}

- (void)requestNativeAdWithOptions:(nullable NSArray<GADAdLoaderOptions *> *)options {
    for (GADNativeAdImageAdLoaderOptions *imageOptions in options) {
        if (![imageOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) {
            continue;
        }
        _shouldDownloadImages = !imageOptions.disableImageLoading;
    }
    
    NSString *accountID = _nativeAdConfig.credentials.settings[GADMAdapterInMobiAccountID];
    
    GADMAdapterInMobiUnifiedNativeAd *__weak weakSelf = self;
    [GADMAdapterInMobiInitializer.sharedInstance
     initializeWithAccountID:accountID
     completionHandler:^(NSError *_Nullable error) {
        GADMAdapterInMobiUnifiedNativeAd *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        if (error) {
            NSLog(@"[InMobi] Initialization failed: %@", error.localizedDescription);
            strongSelf->_nativeRenderCompletionHandler(nil,error);
            return;
        }
        
        [strongSelf requestNativeAd];
    }];
}

- (void)requestNativeAd {
    long long placementId = [_placementIdentifier longLongValue];
    
    if (placementId == 0) {
        NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
                                                                      GADMAdapterInMobiErrorInvalidServerParameters,
                                                                      @"[InMobi] Error - Placement ID not specified.");
        _nativeRenderCompletionHandler(nil,error);
        return;
    }
    
    if ([_nativeAdConfig isTestRequest]) {
        NSLog(@"[InMobi] Please enter your device ID in the InMobi console to recieve test ads from "
              @"Inmobi");
    }
    
    NSLog(@"[InMobi] Requesting native ad from InMobi.");
    _native = [[IMNative alloc] initWithPlacementId:placementId delegate:self];
    
    GADInMobiExtras *extras = [_nativeAdConfig extras];
    if (extras && extras.keywords) {
        [_native setKeywords:extras.keywords];
    }
    
    GADMAdapterInMobiSetTargetingFromAdConfiguration(_nativeAdConfig);
    NSDictionary<NSString *, id> *requestParameters =
    GADMAdapterInMobiCreateRequestParametersFromAdConfiguration(_nativeAdConfig);
    [_native setExtras:requestParameters];
    
    [_native load];
}

#pragma mark - IMNativeDelegate

- (void)nativeDidFinishLoading:(nonnull IMNative *)native {
    NSData *data = [_native.customAdContent dataUsingEncoding:NSUTF8StringEncoding];
    __weak GADMAdapterInMobiUnifiedNativeAd *weakSelf = self;
    [self setupWithData:data
    shouldDownloadImage:_shouldDownloadImages
             imageCache:imageCache
              completed:^{
        GADMAdapterInMobiUnifiedNativeAd *strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf notifyCompletion];
        }
    }];
}

- (void)native:(nonnull IMNative *)native didFailToLoadWithError:(nonnull IMRequestStatus *)error {
    NSLog(@"Native Ad failed to load");
    _nativeRenderCompletionHandler(nil,error);
}

- (void)nativeWillPresentScreen:(nonnull IMNative *)native {
    NSLog(@"[InMobi] Native Will Present screen.");
    [_nativeAdEventDelegate willPresentFullScreenView];
}

- (void)nativeDidPresentScreen:(nonnull IMNative *)native {
    NSLog(@"[InMobi] Native Did Present screen.");
}

- (void)nativeWillDismissScreen:(nonnull IMNative *)native {
    NSLog(@"[InMobi] Native Will dismiss screen.");
    [_nativeAdEventDelegate willDismissFullScreenView];
}

- (void)nativeDidDismissScreen:(nonnull IMNative *)native {
    NSLog(@"[InMobi] Native Did dismiss screen.");
    [_nativeAdEventDelegate didDismissFullScreenView];
}

- (void)userWillLeaveApplicationFromNative:(nonnull IMNative *)native {
    NSLog(@"[InMobi] User will leave application from native.");
    [_nativeAdEventDelegate willBackgroundApplication];
}

- (void)nativeAdImpressed:(nonnull IMNative *)native {
    NSLog(@"[InMobi] InMobi recorded impression successfully.");
    [_nativeAdEventDelegate reportImpression];
}

- (void)native:(nonnull IMNative *)native didInteractWithParams:(nonnull NSDictionary *)params {
    NSLog(@"[InMobi] User did interact with native.");
}

- (void)nativeDidFinishPlayingMedia:(nonnull IMNative *)native {
    NSLog(@"[InMobi] Native ad finished playing media.");
}

- (void)userDidSkipPlayingMediaFromNative:(nonnull IMNative *)native {
    NSLog(@"[InMobi] User did skip playing media from native.");
}

#pragma mark - Setup Data

- (void)setupWithData:(nullable NSData *)data
    shouldDownloadImage:(BOOL)shouldDownloadImage
             imageCache:(nonnull NSCache *)imageCache
            completed:(void (^)())completed {
    if (!data) {
        completed();
        return;
    }
    
    _nativeAdContentDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:kNilOptions
                                                                   error:nil];
    NSDictionary<NSString *, NSString *> *iconDictionary = _nativeAdContentDictionary[ICON];
    
    if (!iconDictionary) {
        completed();
        return;
    }
    
    NSString *iconStringURL = iconDictionary[URL];
    if (![self isValidWithNativeAd:_native imageURL:iconStringURL]) {
        completed();
        return;
    }
    
    NSString *landingURL = _nativeAdContentDictionary[LANDING_URL];
    if (landingURL) {
        _extras = @{LANDING_URL : landingURL};
    }
    NSURL *iconURL = [NSURL URLWithString:iconStringURL];
    
    // Pass a blank image since we are using only mediaview.
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(36, 36), NO, 0.0);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    _mappedImages = @[ [[GADNativeAdImage alloc] initWithImage:img] ];
    
    if (shouldDownloadImage) {
        [self loadImageWithURL:iconURL
                    imageCache:imageCache
                      callback:^(UIImage *image) {
            self->_mappedIcon = [[GADNativeAdImage alloc] initWithImage:image];
            completed();
        }];
        return;
    }
    
    _mappedIcon = [[GADNativeAdImage alloc] initWithURL:iconURL scale:DefaultIconScale];
    completed();
}

#pragma mark - Async Image

- (void)loadImageWithURL:(nonnull NSURL *)url
              imageCache:(nonnull NSCache *)imageCache
                callback:(void (^)(UIImage *))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *cacheKey =
        [url.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        UIImage *cachedImage = [imageCache objectForKey:cacheKey];
        if (!cachedImage) {
            NSData *imageData = [NSData dataWithContentsOfURL:url];
            UIImage *image = [UIImage imageWithData:imageData];
            if (image) {
                cachedImage = image;
                GADMAdapterInMobiCacheSetObjectForKey(imageCache, cacheKey, cachedImage);
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(cachedImage);
        });
    });
}

#pragma mark - Completion

- (void)notifyCompletion {
    if (!_mappedIcon || !_mappedImages) {
        NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
                                                                      GADMAdapterInMobiErrorMissingNativeAssets,
                                                                      @"InMobi returned an ad without image or icon assets.");
        _nativeRenderCompletionHandler(nil,error);
        return;
    }
    
    _nativeAdEventDelegate = _nativeRenderCompletionHandler(self,nil);
    
}

#pragma mark - Helpers

- (BOOL)isValidWithNativeAd:(nonnull IMNative *)native imageURL:(nonnull NSString *)imageURL {
    if (!native.adTitle.length || !native.adDescription.length || !native.adCtaText.length ||
        !native.adIcon || !imageURL.length) {
        return NO;
    }
    return YES;
}

#pragma mark - GADMediatedUnifiedNativeAd

- (nullable NSString *)advertiser {
    return nil;
}

- (nullable NSString *)headline {
    return _native.adTitle;
}

- (nullable NSString *)body {
    return _native.adDescription;
}

- (nullable GADNativeAdImage *)icon {
    return _mappedIcon;
}

- (nullable NSString *)callToAction {
    return _native.adCtaText;
}

- (nullable NSDecimalNumber *)starRating {
    if (_native) {
        return (NSDecimalNumber *)_native.adRating;
    }
    return 0;
}

/// InMobi SDK doesn't have an AdChoices view.
- (nullable UIView *)adChoicesView {
    return nil;
}

- (nullable NSString *)store {
    NSString *landingURL = (NSString *)(_native.adLandingPageUrl.absoluteString);
    if (!landingURL.length) {
        return @"";
    }
    
    NSRange searchedRange = NSMakeRange(0, landingURL.length);
    NSError *error = nil;
    NSRegularExpression *regex =
    [NSRegularExpression regularExpressionWithPattern:@"\\S*:\\/\\/itunes\\.apple\\.com\\S*"
                                              options:0
                                                error:&error];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:landingURL
                                                        options:0
                                                          range:searchedRange];
    if (numberOfMatches == 0) {
        return @"Others";
    }
    return @"iTunes";
}

- (nullable NSString *)price {
    if ([_nativeAdContentDictionary[PRICE] length]) {
        return _nativeAdContentDictionary[PRICE];
    }
    return @"";
}

- (nullable NSArray<GADNativeAdImage *> *)images {
    return _mappedImages;
}

- (nullable NSDictionary<NSString *, id> *)extraAssets {
    return _extras;
}

- (nullable UIView *)mediaView {
    UIView *placeHolderView = [[UIView alloc] initWithFrame:CGRectZero];
    placeHolderView.userInteractionEnabled = NO;
    return placeHolderView;
}

- (BOOL)hasVideoContent {
    return true;
}

- (CGFloat)mediaContentAspectRatio {
    return _aspectRatio;
}

- (void)didRecordClickOnAssetWithName:(nonnull GADNativeAssetIdentifier)assetName
                                 view:(nonnull UIView *)view
                       viewController:(nonnull UIViewController *)viewController {
    if (_native) {
        [_native reportAdClickAndOpenLandingPage];
    }
}

- (void)didRenderInView:(nonnull UIView *)view
    clickableAssetViews:(nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews nonclickableAssetViews: (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
         viewController:(nonnull UIViewController *)viewController {
    GADNativeAdView *adView = (GADNativeAdView *)view;
    GADMediaView *mediaView = adView.mediaView;
    UIView *primaryView = [_native primaryViewOfWidth:mediaView.frame.size.width];
    [mediaView addSubview:primaryView];
    
    _aspectRatio = primaryView.frame.size.width / primaryView.frame.size.height;
}

- (void)didUntrackView:(nullable UIView *)view {
    [_native recyclePrimaryView];
    _native = nil;
}

@end
