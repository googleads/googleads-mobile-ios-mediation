//
//  InMobiMediatedUnifiedNativeAd.m
//  InMobiAdapter
//
//  Created by Niranjan Agrawal on 1/22/16.
//
//

#import "InMobiMediatedUnifiedNativeAd.h"
#import <Foundation/Foundation.h>
#import "NativeAdKeys.h"

static CGFloat const DefaultIconScale = 1.0;

@interface InMobiMediatedUnifiedNativeAd () <InMobiMediatedUnifiedNativeAdDelegate>
@end

@implementation InMobiMediatedUnifiedNativeAd {
  /// Native ad obtained from InMobi.
  IMNative *_native;

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

- (nonnull instancetype)initWithInMobiUnifiedNativeAd:(nonnull IMNative *)unifiedNativeAd
                                              adapter:(nonnull GADMAdapterInMobi *)adapter
                                  shouldDownloadImage:(BOOL)shouldDownloadImage
                                                cache:(nonnull NSCache *)imageCache {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _native = unifiedNativeAd;
    NSData *data = [_native.customAdContent dataUsingEncoding:NSUTF8StringEncoding];
    __weak InMobiMediatedUnifiedNativeAd *weakSelf = self;
    [self setupWithData:data
        shouldDownloadImage:shouldDownloadImage
                 imageCache:imageCache
                  completed:^{
                    [weakSelf notifyCompletion];
                  }];
  }
  return self;
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
  } else {
    _mappedIcon = [[GADNativeAdImage alloc] initWithURL:iconURL scale:DefaultIconScale];
    completed();
  }
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
        [imageCache setObject:cachedImage forKey:cacheKey];
      }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      callback(cachedImage);
    });
  });
}

#pragma mark - Completion

- (void)notifyCompletion {
  if (_mappedIcon && _mappedImages) {
    [self notifyMediatedUnifiedNativeAdSuccessful];
  } else {
    [self notifyMediatedUnifiedNativeAdFailed];
  }
}

- (void)notifyMediatedUnifiedNativeAdSuccessful {
  if ([self respondsToSelector:@selector(inmobiMediatedUnifiedNativeAdSuccessful:)]) {
    [self inmobiMediatedUnifiedNativeAdSuccessful:self];
  }
}

- (void)notifyMediatedUnifiedNativeAdFailed {
  if ([self respondsToSelector:@selector(inmobiMediatedUnifiedNativeAdFailed)]) {
    [self inmobiMediatedUnifiedNativeAdFailed];
  }
}

#pragma mark - Helpers

- (BOOL)isValidWithNativeAd:(nonnull IMNative *)native imageURL:(nonnull NSString *)imageURL {
  if (![[native adTitle] length] || ![[native adDescription] length] ||
      ![[native adCtaText] length] || ![native adIcon] || ![imageURL length]) {
    return NO;
  }
  return YES;
}

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

- (nullable NSString *)store {
  NSString *landingURL = (NSString *)(_native.adLandingPageUrl.absoluteString);
  if (landingURL) {
    NSRange searchedRange = NSMakeRange(0, [landingURL length]);
    NSError *error = nil;
    NSRegularExpression *regex =
        [NSRegularExpression regularExpressionWithPattern:@"\\S*:\\/\\/itunes\\.apple\\.com\\S*"
                                                  options:0
                                                    error:&error];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:landingURL
                                                        options:0
                                                          range:searchedRange];
    if (numberOfMatches == 0)
      return @"Others";
    else
      return @"iTunes";
  }
  return @"";
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

- (void)didRecordClickOnAssetWithName:(GADUnifiedNativeAssetIdentifier)assetName
                                 view:(UIView *)view
                       viewController:(UIViewController *)viewController {
  if (_native) {
    [_native reportAdClickAndOpenLandingPage];
  }
}

- (void)didRenderInView:(UIView *)view
       clickableAssetViews:
           (NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(UIViewController *)viewController {
  GADUnifiedNativeAdView *adView = (GADUnifiedNativeAdView *)view;
  GADMediaView *mediaView = adView.mediaView;
  UIView *primaryView = [_native primaryViewOfWidth:mediaView.frame.size.width];
  [mediaView addSubview:primaryView];

  _aspectRatio = primaryView.frame.size.width / primaryView.frame.size.height;
}

- (void)didUntrackView:(UIView *)view {
  [_native recyclePrimaryView];
  _native = nil;
}

- (void)inmobiMediatedUnifiedNativeAdFailed {
  GADRequestError *reqError = [GADRequestError errorWithDomain:kGADErrorDomain
                                                          code:kGADErrorMediationNoFill
                                                      userInfo:nil];
  [self.adapter.connector adapter:self.adapter didFailAd:reqError];
}

- (void)inmobiMediatedUnifiedNativeAdSuccessful:(InMobiMediatedUnifiedNativeAd *)ad {
  if (self.adapter != nil && self.adapter.connector != nil) {
    [self.adapter.connector adapter:self.adapter didReceiveMediatedUnifiedNativeAd:ad];
  }
}

@end
