#import "GADMAdapterMoPub.h"
#import "GADMoPubNetworkExtras.h"
#import "MPLogging.h"
#import "MPAdView.h"
#import "MPInterstitialAdController.h"
#import "MPNativeAdDelegate.h"
#import "MPNativeAd.h"
#import "MPStaticNativeAdRendererSettings.h"
#import "MPStaticNativeAdRenderer.h"
#import "MPNativeAdRequest.h"
#import "MPNativeAdRequestTargeting.h"
#import "MoPubAdapterMediatedNativeAd.h"
#import "MPNativeAdConstants.h"
#import "MPImageDownloadQueue.h"
#import "MPNativeAdUtils.h"
#import "MPNativeCache.h"

/// Constant for adapter error domain.
static NSString *const kAdapterErrorDomain = @"com.mopub.mobileads.MoPubAdapter";

@interface GADMAdapterMoPub () <MPNativeAdDelegate, MPAdViewDelegate, MPInterstitialAdControllerDelegate>

/// Connector from Google Mobile Ads SDK to receive ad configurations.
@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;

@property(nonatomic, strong) MPAdView *bannerAd;

@property(nonatomic, strong) MPInterstitialAdController *interstitialAd;

@property(nonatomic, strong) MPNativeAd *nativeAd;

@property(nonatomic, strong) MoPubAdapterMediatedNativeAd *mediatedAd;

@property (nonatomic, strong) MPImageDownloadQueue *imageDownloadQueue;

@property (nonatomic, strong) NSMutableDictionary *imagesDictionary;

@property (nonatomic, strong) GADNativeAdViewAdOptions *nativeAdViewAdOptions;

@end

@implementation GADMAdapterMoPub


+ (NSString *)adapterVersion {
  return @"4.11.1.beta0";
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMoPubNetworkExtras class];
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _connector = connector;
    _imageDownloadQueue = [[MPImageDownloadQueue alloc] init];
  }
  return self;
}


- (void)getInterstitial {
    self.interstitialAd = [MPInterstitialAdController interstitialAdControllerForAdUnitId:[self.connector credentials][@"pubid"]];
    self.interstitialAd.delegate = self;
    [self.interstitialAd loadAd];
    NSLog(@"Requesting interstitial from MoPub");
}

- (void)stopBeingDelegate {
    self.bannerAd.delegate = nil;
    self.interstitialAd.delegate = nil;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
    if (self.interstitialAd.ready) {
        [self.interstitialAd showFromViewController:rootViewController];
    }
}

#pragma mark MoPub Ad Interstitial delegate methods

- (void)interstitialDidLoadAd:(MPInterstitialAdController *)interstitial {
    [self.connector adapterDidReceiveInterstitial:self];
}

- (void)interstitialDidFailToLoadAd:(MPInterstitialAdController *)interstitial {
    NSError *adapterError = [NSError errorWithDomain:kAdapterErrorDomain code:kGADErrorMediationNoFill userInfo:nil];
    [self.connector adapter:self didFailAd:adapterError];
}

- (void)interstitialWillAppear:(MPInterstitialAdController *)interstitial {
    [self.connector adapterWillPresentInterstitial:self];
}

- (void)interstitialWillDisappear:(MPInterstitialAdController *)interstitial {
    [self.connector adapterWillDismissInterstitial:self];
}

- (void)interstitialDidDisappear:(MPInterstitialAdController *)interstitial {
    [self.connector adapterDidDismissInterstitial:self];
}

- (void)interstitialDidReceiveTapEvent:(MPInterstitialAdController *)interstitial {
    [self.connector adapterDidGetAdClick:self];
}


//Loading Banner Ads

- (void)getBannerWithSize:(GADAdSize)adSize {
    
    self.bannerAd = [[MPAdView alloc] initWithAdUnitId:[self.connector credentials][@"pubid"] size: CGSizeMake(adSize.size.width, adSize.size.height) ] ;
    
    self.bannerAd.delegate = self;    
    [self.bannerAd loadAd];
    NSLog(@"Requesting banner from MoPub Ad Network");
}

#pragma mark MoPub Ad View delegate methods

- (void)adViewDidLoadAd:(MPAdView *)view {
    [self.connector adapter:self didReceiveAdView:view];
}

- (void)adViewDidFailToLoadAd:(MPAdView *)view {
    
    NSString *errorDesc = [NSString stringWithFormat: @"Mopub failed to fill the ad"];
    NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys: errorDesc, NSLocalizedDescriptionKey, nil];
    
    [self.connector adapter:self didFailAd:[NSError errorWithDomain:kGADErrorDomain code:kGADErrorInvalidRequest userInfo:errorInfo]];
    
}

- (void)willLeaveApplicationFromAd:(MPAdView *)view {
    [self.connector adapterWillLeaveApplication:self];
}

- (void)willPresentModalViewForAd:(MPAdView *)view {
    [self.connector adapterDidGetAdClick:self];
    [self.connector adapterWillPresentFullScreenModal:self];
}

- (void)didDismissModalViewForAd:(MPAdView *)view {
    [self.connector adapterWillDismissFullScreenModal:self];
    [self.connector adapterDidDismissFullScreenModal:self];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
    return YES;
}


// Loading Native Ads

- (void)getNativeAdWithAdTypes:(NSArray *)adTypes options:(NSArray *)options {
  
  if (![adTypes containsObject:kGADAdLoaderAdTypeNativeAppInstall]) {
    NSError *adapterError = [NSError errorWithDomain:kAdapterErrorDomain code:kGADErrorInvalidArgument userInfo:nil];
        [self.connector adapter:self didFailAd:adapterError];
    return;
  }
  
  MPStaticNativeAdRendererSettings *settings = [[MPStaticNativeAdRendererSettings alloc] init];
  
  MPNativeAdRendererConfiguration *config = [MPStaticNativeAdRenderer rendererConfigurationWithRendererSettings:settings];
  NSString *moPubPublisherId = [self.connector credentials][@"pubid"];
  MPNativeAdRequest *adRequest = [MPNativeAdRequest requestWithAdUnitIdentifier: moPubPublisherId rendererConfigurations:@[config]];
                                                
  MPNativeAdRequestTargeting *targeting = [MPNativeAdRequestTargeting targeting];
  CLLocation *currentlocation = [[CLLocation alloc] initWithLatitude:self.connector.userLatitude longitude:self.connector.userLongitude];
  targeting.location = currentlocation;
  NSSet *desiredAssets = [NSSet setWithObjects:
                          kAdTitleKey,
                          kAdTextKey,
                          kAdIconImageKey,
                          kAdMainImageKey,
                          kAdCTATextKey, nil];
  targeting.desiredAssets = desiredAssets;

  adRequest.targeting = targeting;
  [adRequest startWithCompletionHandler:^(MPNativeAdRequest *request, MPNativeAd *response, NSError *error) {
      if (error) {
          [self.connector adapter:self didFailAd:error];
      }
      else {
          self.nativeAd = response;
          self.nativeAd.delegate = self;
          BOOL shouldDownlaodImages = YES;

          if(options!=nil){
              
              for (GADAdLoaderOptions *loaderOptions in options) {

                  if([loaderOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) {
                      
                      GADNativeAdImageAdLoaderOptions *imageOptions = (GADNativeAdImageAdLoaderOptions *)loaderOptions;
                      shouldDownlaodImages = !imageOptions.disableImageLoading;
                  }

                  else if ([loaderOptions isKindOfClass:[GADNativeAdViewAdOptions class]]) {
                          _nativeAdViewAdOptions = (GADNativeAdViewAdOptions *)loaderOptions;
                  }
                  
              }
          }
          
          if(shouldDownlaodImages) {
              [self loadNativeAdImages];
          }
          else {
              _mediatedAd = [[MoPubAdapterMediatedNativeAd alloc] initWithMoPubNativeAd:self.nativeAd mappedImages:nil nativeAdViewOptions:_nativeAdViewAdOptions networkExtras:[_connector networkExtras]];
              [self.connector adapter:self didReceiveMediatedNativeAd:_mediatedAd];
              return;
          }

      }

  }];
    
  
  MPLogDebug(@"Requesting native ad from MoPub Ad Network");
}

//Helper classes for downloading images

- (void)loadNativeAdImages {
    
    NSMutableArray *imageURLs = [NSMutableArray array];
    for (NSString *key in [self.nativeAd.properties allKeys]) {
        if ([[key lowercaseString] hasSuffix:@"image"] && [[self.nativeAd.properties objectForKey:key] isKindOfClass:[NSString class]]) {
            if ([self.nativeAd.properties objectForKey:key]) {
                NSURL *URL = [NSURL URLWithString:self.nativeAd.properties[key]];
                [imageURLs addObject:URL];
            }
            else
            {
                NSError *adapterError = [NSError errorWithDomain:kAdapterErrorDomain code:kGADErrorReceivedInvalidResponse userInfo:nil];
                [self.connector adapter:self didFailAd:adapterError];
                return;
            }
        }
    }
    
     [self precacheImagesWithURL:imageURLs];
}

- (NSString *) returnImageKey: (NSString *) imageURL
{
    for (NSString *key in [self.nativeAd.properties allKeys]) {
        if ([[key lowercaseString] hasSuffix:@"image"] && [[self.nativeAd.properties objectForKey:key] isKindOfClass:[NSString class]]) {
           
            if([[self.nativeAd.properties objectForKey:key] isEqualToString:imageURL]) {
                return key;
            }
           
        }
    }
    
    return nil;
}

- (void)precacheImagesWithURL:(NSArray *)imageURLs
{
    _imagesDictionary = [[NSMutableDictionary alloc] init];
    
    for (NSURL *imageURL in imageURLs) {
        NSData *cachedImageData = [[MPNativeCache sharedCache] retrieveDataForKey:imageURL.absoluteString];
    
        UIImage *image = [UIImage imageWithData:cachedImageData];
    
        if (image) {
            // By default, the image data isn't decompressed until set on a UIImageView, on the main thread. This
            // can result in poor scrolling performance. To fix this, we force decompression in the background before
            // assignment to a UIImageView.
            UIGraphicsBeginImageContext(CGSizeMake(1, 1));
            [image drawAtPoint:CGPointZero];
            UIGraphicsEndImageContext();
        
            GADNativeAdImage *nativeAdImage = [[GADNativeAdImage alloc] initWithImage:image];

            [_imagesDictionary setObject:nativeAdImage forKey:[self returnImageKey:imageURL.absoluteString]];

        }
       
    }
    
    if (_imagesDictionary.count < imageURLs.count) {
        
        MPLogDebug(@"Cache miss on %@. Re-downloading...", imageURLs);
        
        __weak typeof(self) weakSelf = self;
        [self.imageDownloadQueue addDownloadImageURLs:imageURLs
                                      completionBlock:^(NSArray *errors) {
                                          
                                          __strong typeof(self) strongSelf = weakSelf;
                                          if (strongSelf) {
                                              if (errors.count == 0) {
                                                  for (NSURL *imageURL in imageURLs) {

                                                      UIImage *image = [UIImage imageWithData:[[MPNativeCache sharedCache] retrieveDataForKey:imageURL.absoluteString]];

                                                      GADNativeAdImage *nativeAdImage = [[GADNativeAdImage alloc] initWithImage:image];

                                                      [strongSelf.imagesDictionary setObject:nativeAdImage forKey:[strongSelf returnImageKey:imageURL.absoluteString]];
                                                  }
                                                  
                                                  if ([strongSelf.imagesDictionary objectForKey:kAdIconImageKey] && [strongSelf.imagesDictionary objectForKey:kAdMainImageKey]) {
                                                      
                                                  strongSelf.mediatedAd = [[MoPubAdapterMediatedNativeAd alloc] initWithMoPubNativeAd:strongSelf.nativeAd mappedImages:strongSelf.imagesDictionary nativeAdViewOptions:strongSelf.nativeAdViewAdOptions networkExtras:[_connector networkExtras]];
                                                   [strongSelf.connector adapter:strongSelf didReceiveMediatedNativeAd:strongSelf.mediatedAd];

                                                      
                                                  }

                                              } else {
                                                  MPLogDebug(@"Failed to download images. Giving up for now.");
                                                  NSError *adapterError = [NSError errorWithDomain:kAdapterErrorDomain code:kGADErrorNetworkError userInfo:nil];
                                                  [strongSelf.connector adapter:strongSelf didFailAd:adapterError];
                                                  return;
                                              }
                                          } else {
                                              MPLogDebug(@"MPNativeAd deallocated before loadImageForURL:intoImageView: download completion block was called");
                                              NSError *adapterError = [NSError errorWithDomain:kAdapterErrorDomain code:kGADErrorInternalError userInfo:nil];
                                              [strongSelf.connector adapter:strongSelf didFailAd:adapterError];
                                              return;
                                          }
                                      }];
    } else { 
        _mediatedAd = [[MoPubAdapterMediatedNativeAd alloc] initWithMoPubNativeAd:self.nativeAd mappedImages:_imagesDictionary nativeAdViewOptions:_nativeAdViewAdOptions networkExtras:[_connector networkExtras]];
        [self.connector adapter:self didReceiveMediatedNativeAd:_mediatedAd];
    }
}

#pragma mark MPNativeAdDelegate Methods
- (UIViewController *)viewControllerForPresentingModalView {
    return [self.connector viewControllerForPresentingModalView];
}

- (void)willPresentModalForNativeAd:(MPNativeAd *)nativeAd {
    [GADMediatedNativeAdNotificationSource mediatedNativeAdWillPresentScreen:self.mediatedAd];
}

- (void)didDismissModalForNativeAd:(MPNativeAd *)nativeAd {
    [GADMediatedNativeAdNotificationSource mediatedNativeAdWillDismissScreen:self.mediatedAd];
    [GADMediatedNativeAdNotificationSource mediatedNativeAdDidDismissScreen:self.mediatedAd];
}

- (void)willLeaveApplicationFromNativeAd:(MPNativeAd *)nativeAd {
   [GADMediatedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication: self.mediatedAd];
}

@end

