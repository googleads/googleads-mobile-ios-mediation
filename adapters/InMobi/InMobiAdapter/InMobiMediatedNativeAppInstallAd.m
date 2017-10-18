//
//  InMobiMediatedNativeAppInstallAd.m
//  InMobiAdapter
//
//  Created by Niranjan Agrawal on 1/22/16.
//
//

#import <Foundation/Foundation.h>
#import "InMobiMediatedNativeAppInstallAd.h"
#import <GoogleMobileAds/GADMediatedNativeAdDelegate.h>
#import "NativeAdKeys.h"

@interface InMobiMediatedNativeAppInstallAd () <GADMediatedNativeAdDelegate,
                                                InMobiMediatedNativeAppInstallAdDelegate>

@property(nonatomic, strong) IMNative *native;
@property(nonatomic, strong) GADNativeAdImage *mappedIcon;
@property(nonatomic, copy) NSDictionary *extras;
@property(nonatomic, strong) NSDictionary *nativeAdContentDictionary;

@end

@implementation InMobiMediatedNativeAppInstallAd

//@synthesize adDelegate;
@synthesize adapter = adapter_;
//@synthesize connector = _connector;

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
  NSError *error = nil;
  SEL inmobiMediatedNativeAppInstallAdSuccessful = @selector(inmobiMediatedNativeAppInstallAdSuccessful:);

  if (data) {
    self.nativeAdContentDictionary =
        [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (![[self.nativeAdContentDictionary objectForKey:TITLE] length] ||
        ![[self.nativeAdContentDictionary objectForKey:DESCRIPTION] length] ||
        ![[self.nativeAdContentDictionary objectForKey:CTA] length] ||
        ![self.nativeAdContentDictionary objectForKey:ICON] ||
        ![self.nativeAdContentDictionary objectForKey:SCREENSHOTS]) {
      [self inmobiMediatedNativeAppInstallAdFailed];
      return nil;
    }
    NSDictionary *iconDictionary = [self.nativeAdContentDictionary objectForKey:ICON];
    self.extras = [[NSDictionary alloc]
        initWithObjectsAndKeys:[self.nativeAdContentDictionary objectForKey:LANDING_URL],
                               LANDING_URL, nil];

    if (iconDictionary) {
        NSString *iconStringURL = [iconDictionary objectForKey:URL];
        NSURL *iconURL = [NSURL URLWithString:iconStringURL];
        CGFloat iconScale = 1.0;
            
        self.mappedIcon = [[GADNativeAdImage alloc] initWithURL:iconURL scale:iconScale];
        if([self respondsToSelector:inmobiMediatedNativeAppInstallAdSuccessful]){
            [self inmobiMediatedNativeAppInstallAdSuccessful:self];
        }
      }
  }
  return self;
}

- (NSString *)headline {
    if( [self.native.adTitle length]){
        return self.native.adTitle;
    }
    [self inmobiMediatedNativeAppInstallAdFailed];
    return @"";
}

- (NSString *)body {
    if([self.native.adDescription length]){
        return self.native.adDescription;
    }
    [self inmobiMediatedNativeAppInstallAdFailed];
    return @"";
}

- (GADNativeAdImage *)icon {
    if(self.mappedIcon)
        return self.mappedIcon;
    [self inmobiMediatedNativeAppInstallAdFailed];
    return nil;
}

- (NSString *)callToAction {
    if([self.native.adCtaText length]){
        return self.native.adCtaText;
    }
    [self inmobiMediatedNativeAppInstallAdFailed];
    return @"";
}

- (NSDecimalNumber *)starRating {
    if(self.native){
        return (NSDecimalNumber*)self.native.adRating;
    }
    return 0;
}

- (NSString *)store {
    NSString *landingURL = (NSString*)(self.native.adLandingPageUrl.absoluteString);
    if(landingURL){
        NSRange   searchedRange = NSMakeRange(0, [landingURL length]);
        NSError  *error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\S*:\\/\\/itunes\\.apple\\.com\\S*" options:0 error:&error];
        NSUInteger numberOfMatches = [regex numberOfMatchesInString:landingURL options:0 range: searchedRange];
        if(numberOfMatches == 0)
            return @"Others";
        else
            return @"Itunes";
    }
    return @"";
}

- (NSString *)price {
    if([[self.nativeAdContentDictionary objectForKey:PRICE] length]){
        return [self.nativeAdContentDictionary objectForKey:PRICE];
    }
    return @"";
}

- (NSArray * _Nullable)images {
    return nil;
}


- (NSDictionary *)extraAssets {
  return self.extras;
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
    GADNativeAppInstallAdView* adView = (GADNativeAppInstallAdView*)view;
    GADMediaView *mediaView = adView.mediaView;
    UIView* primaryView = [self.native primaryViewOfWidth:mediaView.frame.size.width];
    [mediaView addSubview:primaryView];
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd didUntrackView:(UIView *)view {
    [self.native recyclePrimaryView];
    self.native = nil;
}
 
- (void)inmobiMediatedNativeAppInstallAdFailed {
  GADRequestError *reqError =
      [GADRequestError errorWithDomain:kGADErrorDomain code:kGADErrorMediationNoFill userInfo:nil];
  [self.adapter.connector adapter:self.adapter didFailAd:reqError];
}

- (void)inmobiMediatedNativeAppInstallAdSuccessful:(InMobiMediatedNativeAppInstallAd *)ad {
  if (self.adapter != nil && self.adapter.connector != nil) {
    [self.adapter.connector adapter:self.adapter didReceiveMediatedNativeAd:ad];
  }
}

@end
