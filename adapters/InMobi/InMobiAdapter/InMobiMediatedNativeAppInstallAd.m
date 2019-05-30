//
//  InMobiMediatedNativeAppInstallAd.m
//  InMobiAdapter
//
//  Created by Niranjan Agrawal on 1/22/16.
//
//

#import "InMobiMediatedNativeAppInstallAd.h"
#import <Foundation/Foundation.h>
#import "NativeAdKeys.h"

static CGFloat const DefaultIconScale = 1.0;

@interface InMobiMediatedNativeAppInstallAd () <GADMediatedNativeAdDelegate,
                                                InMobiMediatedNativeAppInstallAdDelegate>

@property(nonatomic, strong) IMNative *native;
@property(nonatomic, strong) GADNativeAdImage *mappedIcon;
@property(nonatomic, copy) NSArray *mappedImages;
@property(nonatomic, copy) NSDictionary *extras;
@property(nonatomic, strong) NSDictionary *nativeAdContentDictionary;

@end

@implementation InMobiMediatedNativeAppInstallAd

@synthesize adapter = adapter_;

- (instancetype)initWithInMobiNativeAppInstallAd:(IMNative *)nativeAd
                                     withAdapter:(GADMAdapterInMobi *)adapter
                             shouldDownloadImage:(BOOL)shouldDownloadImage
                                       withCache:(NSCache *)imageCache {
  if (!nativeAd) {
    return nil;
  }
  self = [super init];
  self.adapter = adapter;
  self.native = nativeAd;

  NSData *data = [self.native.customAdContent dataUsingEncoding:NSUTF8StringEncoding];
  __weak InMobiMediatedNativeAppInstallAd *weakSelf = self;
  [self setupWithData:data
      shouldDownloadImage:shouldDownloadImage
               imageCache:imageCache
                completed:^{
                  [weakSelf notifyCompletion];
                }];
  return self;
}

#pragma mark - Setup Data

- (void)setupWithData:(NSData *)data
    shouldDownloadImage:(BOOL)shouldDownloadImage
             imageCache:(NSCache *)imageCache
              completed:(void (^)())completed {
  if (!data) {
    completed();
    return;
  }

  self.nativeAdContentDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:kNilOptions
                                                                     error:nil];
  NSDictionary *iconDictionary = [self.nativeAdContentDictionary objectForKey:ICON];

  if (!iconDictionary) {
    completed();
    return;
  }

  NSString *iconStringURL = [iconDictionary objectForKey:URL];
  if ([self isValidWithNativeAd:self.native imageURL:iconStringURL]) {
    self.extras = [[NSDictionary alloc]
        initWithObjectsAndKeys:[self.nativeAdContentDictionary objectForKey:LANDING_URL],
                               LANDING_URL, nil];
    NSURL *iconURL = [NSURL URLWithString:iconStringURL];

    // Pass a blank image since we are using only mediaview.
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(36, 36), NO, 0.0);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    self.mappedImages = @[ [[GADNativeAdImage alloc] initWithImage:img] ];

    if (!shouldDownloadImage) {
      self.mappedIcon = [[GADNativeAdImage alloc] initWithURL:iconURL scale:DefaultIconScale];
      completed();
    } else {
      NSURL *imageURL = [NSURL URLWithString:iconStringURL];
      __weak InMobiMediatedNativeAppInstallAd *weakSelf = self;
      [self loadImageWithURL:imageURL
                  imageCache:imageCache
                    callback:^(UIImage *image) {
                      weakSelf.mappedIcon = [[GADNativeAdImage alloc] initWithImage:image];
                      completed();
                    }];
    }
  } else {
    completed();
  }
}

#pragma mark - Async Image

- (void)loadImageWithURL:(NSURL *)url
              imageCache:(NSCache *)imageCache
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
  if (self.mappedIcon && self.mappedImages) {
    [self notifyMediatedNativeAppInstallAdSuccessful];
  } else {
    [self notifyMediatedNativeAppInstallAdFailed];
  }
}

- (void)notifyMediatedNativeAppInstallAdSuccessful {
  if ([self respondsToSelector:@selector(inmobiMediatedNativeAppInstallAdSuccessful:)]) {
    [self inmobiMediatedNativeAppInstallAdSuccessful:self];
  }
}

- (void)notifyMediatedNativeAppInstallAdFailed {
  if ([self respondsToSelector:@selector(inmobiMediatedNativeAppInstallAdFailed)]) {
    [self inmobiMediatedNativeAppInstallAdFailed];
  }
}

#pragma mark - Helpers

- (BOOL)isValidWithNativeAd:(IMNative *)native imageURL:(NSString *)imageURL {
  if (![[native adTitle] length] || ![[native adDescription] length] ||
      ![[native adCtaText] length] || ![native adIcon] || ![imageURL length]) {
    return NO;
  }
  return YES;
}

- (NSString *)headline {
  return self.native.adTitle;
}

- (NSString *)body {
  return self.native.adDescription;
}

- (GADNativeAdImage *)icon {
  return self.mappedIcon;
}

- (NSString *)callToAction {
  return self.native.adCtaText;
}

- (NSDecimalNumber *)starRating {
  if (self.native) {
    return (NSDecimalNumber *)self.native.adRating;
  }
  return 0;
}

- (NSString *)store {
  NSString *landingURL = (NSString *)(self.native.adLandingPageUrl.absoluteString);
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

- (NSString *)price {
  if ([[self.nativeAdContentDictionary objectForKey:PRICE] length]) {
    return [self.nativeAdContentDictionary objectForKey:PRICE];
  }
  return @"";
}

- (NSArray *)images {
  return self.mappedImages;
}

- (NSDictionary *)extraAssets {
  return self.extras;
}

- (UIView *GAD_NULLABLE_TYPE)mediaView {
  UIView *placeHolderView = [[UIView alloc] initWithFrame:CGRectZero];
  placeHolderView.userInteractionEnabled = NO;
  return placeHolderView;
}

- (BOOL)hasVideoContent {
  return true;
}

- (id<GADMediatedNativeAdDelegate>)mediatedNativeAdDelegate {
  return self;
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd
    didRecordClickOnAssetWithName:(NSString *)assetName
                             view:(UIView *)view
                   viewController:(UIViewController *)viewController {
  if (self.native) {
    [self.native reportAdClickAndOpenLandingPage];
  }
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd
         didRenderInView:(UIView *)view
          viewController:(UIViewController *)viewController {
  GADNativeAppInstallAdView *adView = (GADNativeAppInstallAdView *)view;
  GADMediaView *mediaView = adView.mediaView;
  UIView *primaryView = [self.native primaryViewOfWidth:mediaView.frame.size.width];
  [mediaView addSubview:primaryView];
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd didUntrackView:(UIView *)view {
  [self.native recyclePrimaryView];
  self.native = nil;
}

- (void)inmobiMediatedNativeAppInstallAdFailed {
  GADRequestError *reqError = [GADRequestError errorWithDomain:kGADErrorDomain
                                                          code:kGADErrorMediationNoFill
                                                      userInfo:nil];
  [self.adapter.connector adapter:self.adapter didFailAd:reqError];
}

- (void)inmobiMediatedNativeAppInstallAdSuccessful:(InMobiMediatedNativeAppInstallAd *)ad {
  if (self.adapter != nil && self.adapter.connector != nil) {
    [self.adapter.connector adapter:self.adapter didReceiveMediatedNativeAd:ad];
  }
}

@end
