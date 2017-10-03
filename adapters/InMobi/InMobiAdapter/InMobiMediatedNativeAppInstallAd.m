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
@property(nonatomic, copy) NSArray *mappedImages;
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
  // self.connector = connector;
  self.native = nativeAd;
  NSData *data = [self.native.customAdContent dataUsingEncoding:NSUTF8StringEncoding];
  NSError *error = nil;

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
    NSDictionary *imageDictionary = [self.nativeAdContentDictionary objectForKey:SCREENSHOTS];
    self.extras = [[NSDictionary alloc]
        initWithObjectsAndKeys:[self.nativeAdContentDictionary objectForKey:LANDING_URL],
                               LANDING_URL, nil];

    if (imageDictionary && iconDictionary) {
      NSString *imageStringURL = [imageDictionary objectForKey:URL];
      NSURL *imageURL = [NSURL URLWithString:imageStringURL];
      NSString *iconStringURL = [iconDictionary objectForKey:URL];
      NSURL *iconURL = [NSURL URLWithString:iconStringURL];
        CGFloat imageScale;
        CGFloat iconScale;
        if(!shouldDownloadImage){
            SEL inmobiMediatedNativeAppInstallAdSuccessful = @selector(inmobiMediatedNativeAppInstallAdSuccessful:);
            if([imageDictionary objectForKey:ASPECT_RATIO]){
                imageScale = [[imageDictionary objectForKey:ASPECT_RATIO] floatValue];
            }
            else{
                CGFloat width = [[imageDictionary objectForKey:WIDTH] floatValue];
                CGFloat height = [[imageDictionary objectForKey:HEIGHT] floatValue];
                if(width > 0 && height > 0){
                    imageScale = width / height;
                }
            }
            self.mappedImages = @[ [[GADNativeAdImage alloc] initWithURL:imageURL scale:imageScale]];
            
            if([iconDictionary objectForKey:ASPECT_RATIO]){
                iconScale = [[iconDictionary objectForKey:ASPECT_RATIO] floatValue];
            }
            else{
                CGFloat width = [[iconDictionary objectForKey:WIDTH] floatValue];
                CGFloat height = [[iconDictionary objectForKey:HEIGHT] floatValue];
                if(width > 0 && height > 0){
                    iconScale = width / height;
                }
            }
            
            self.mappedIcon = [[GADNativeAdImage alloc] initWithURL:iconURL scale:iconScale];
            if([self respondsToSelector:inmobiMediatedNativeAppInstallAdSuccessful]){
                [self inmobiMediatedNativeAppInstallAdSuccessful:self];
            }
        } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
          UIImage *img, *icon;
          [imageStringURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

          UIImage *cachedImage = [imageCache objectForKey:imageStringURL];
          if (cachedImage) {
            img = cachedImage;
          } else {
            NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageStringURL]];
            img = [UIImage imageWithData:imageData];
            if (img != nil) {
              [imageCache setObject:img forKey:imageStringURL];
            }
          }
          if (img != nil) {
            self.mappedImages = @[ [[GADNativeAdImage alloc] initWithImage:img] ];
          } else {
            [self inmobiMediatedNativeAppInstallAdFailed];
            return;
          }

          [iconStringURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

          UIImage *cacheIcon = [imageCache objectForKey:iconStringURL];
          if (cacheIcon) {
            icon = cacheIcon;
          } else {
            NSData *iconData = [NSData dataWithContentsOfURL:[NSURL URLWithString:iconStringURL]];
            icon = [UIImage imageWithData:iconData];
            if (icon != nil) {
              [imageCache setObject:icon forKey:iconStringURL];
            }
          }

          if (icon != nil) {
            self.mappedIcon = [[GADNativeAdImage alloc] initWithImage:icon];
          } else {
            [self inmobiMediatedNativeAppInstallAdFailed];
            return;
          }

          [self inmobiMediatedNativeAppInstallAdSuccessful:self];
        });
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

- (NSArray *)images {
    if(self.mappedImages)
        return self.mappedImages;
    [self inmobiMediatedNativeAppInstallAdFailed];
    return nil;
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
    if([self.nativeAdContentDictionary objectForKey:IMPRESSION_TRACKERS]){
        NSArray* impressionURLs = [self.nativeAdContentDictionary objectForKey:IMPRESSION_TRACKERS];
        NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
        [request setHTTPMethod:@"GET"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            for(int i=0; i < [impressionURLs count]; i++){
                NSString *url = [impressionURLs objectAtIndex:i];
                NSDate *currentDate = [[NSDate alloc] init];
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy.MM.dd.HH.mm.ss.SS"];
                
                NSString *timeStamp = [dateFormatter stringFromDate:currentDate];
                url =[ url stringByReplacingOccurrencesOfString:@"\\/" withString:@"/" ];
                url =[ url stringByReplacingOccurrencesOfString:@"$TS" withString:timeStamp ];
                [request setURL:[NSURL URLWithString:url]];
                NSError *error = nil;
                NSHTTPURLResponse *responseCode = nil;
                NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
                for(int j=0; j < 3 && [responseCode statusCode]!=200; j++){
                    NSLog(@"Impression beacon failed");
                    oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
                }
            }
        });
    }
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd didUntrackView:(UIView *)view {
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
