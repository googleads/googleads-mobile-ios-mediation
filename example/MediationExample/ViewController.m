//
// Copyright (C) 2015 Google, Inc.
//
// ViewController.m
// Mediation Example
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "ViewController.h"

@import GoogleMobileAds;

#import "../Adapter/SampleAdapterConstants.h"
#import "../CustomEvent/SampleCustomEventConstants.h"
#import "ExampleNativeAppInstallAdView.h"
#import "ExampleNativeContentAdView.h"

NSString *const kCustomEventBannerAdUnitID = @"ca-app-pub-3940256099942544/2493674513";
NSString *const kCustomEventInterstitialAdUnitID = @"ca-app-pub-3940256099942544/3970407716";
NSString *const kCustomEventNativeAdUnitID = @"ca-app-pub-3940256099942544/2099734914";
NSString *const kAdapterBannerAdUnitID = @"ca-app-pub-3940256099942544/5855720519";
NSString *const kAdapterInterstitialAdUnitID = @"ca-app-pub-3940256099942544/8809186917";
NSString *const kAdapterNativeAdUnitID = @"ca-app-pub-3940256099942544/2239335711";

@interface ViewController () <GADInterstitialDelegate, GADNativeAppInstallAdLoaderDelegate,
                              GADNativeContentAdLoaderDelegate>

@property(nonatomic, weak) IBOutlet GADBannerView *adapterBanner;
@property(nonatomic, weak) IBOutlet GADBannerView *customEventBanner;

@property(nonatomic, weak) IBOutlet UIButton *adapterInterstitialButton;
@property(nonatomic, weak) IBOutlet UIButton *customEventInterstitialButton;

@property(nonatomic, weak) IBOutlet UIView *adapterNativeAdPlaceholder;
@property(nonatomic, weak) IBOutlet UIView *customEventNativeAdPlaceholder;

@property(nonatomic, strong) GADInterstitial *adapterInterstitial;
@property(nonatomic, strong) GADInterstitial *customEventInterstitial;

@property(nonatomic, strong) UIView *adapterNativeAdView;
@property(nonatomic, strong) UIView *customEventNativeAdView;

/// You must keep a strong reference to the GADAdLoader during the ad loading process.
@property(nonatomic, strong) GADAdLoader *adapterAdLoader;
@property(nonatomic, strong) GADAdLoader *customEventAdLoader;

/// Shows the most recently loaded custom event interstitial in response to a button tap.
- (IBAction)showCustomEventInterstitial:(UIButton *)sender;

/// Shows the most recently loaded adapter interstitial in response to a button tap.
- (IBAction)showAdapterInterstitial:(UIButton *)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.customEventBanner.adUnitID = kCustomEventBannerAdUnitID;
  self.customEventBanner.rootViewController = self;
  [self.customEventBanner loadRequest:[GADRequest request]];

  self.adapterBanner.adUnitID = kAdapterBannerAdUnitID;
  self.adapterBanner.rootViewController = self;
  [self.adapterBanner loadRequest:[GADRequest request]];

  [self requestCustomEventInterstitial];
  [self requestAdapterInterstitial];

  GADNativeAdViewAdOptions *adViewOptions = [[GADNativeAdViewAdOptions alloc] init];
  adViewOptions.preferredAdChoicesPosition = GADAdChoicesPositionBottomRightCorner;

  self.customEventAdLoader = [[GADAdLoader alloc]
        initWithAdUnitID:kCustomEventNativeAdUnitID
      rootViewController:self
                 adTypes:@[ kGADAdLoaderAdTypeNativeAppInstall, kGADAdLoaderAdTypeNativeContent ]
                 options:@[ adViewOptions ]];
  self.customEventAdLoader.delegate = self;
  [self.customEventAdLoader loadRequest:[GADRequest request]];

  self.adapterAdLoader = [[GADAdLoader alloc]
        initWithAdUnitID:kAdapterNativeAdUnitID
      rootViewController:self
                 adTypes:@[ kGADAdLoaderAdTypeNativeAppInstall, kGADAdLoaderAdTypeNativeContent ]
                 options:@[ adViewOptions ]];
  self.adapterAdLoader.delegate = self;
  [self.adapterAdLoader loadRequest:[GADRequest request]];
}

- (void)requestCustomEventInterstitial {
  self.customEventInterstitial =
      [[GADInterstitial alloc] initWithAdUnitID:kCustomEventInterstitialAdUnitID];
  self.customEventInterstitial.delegate = self;
  [self.customEventInterstitial loadRequest:[GADRequest request]];
}

- (void)requestAdapterInterstitial {
  self.adapterInterstitial =
      [[GADInterstitial alloc] initWithAdUnitID:kAdapterInterstitialAdUnitID];
  self.adapterInterstitial.delegate = self;
  [self.adapterInterstitial loadRequest:[GADRequest request]];
}

- (IBAction)showCustomEventInterstitial:(UIButton *)sender {
  if (self.customEventInterstitial.isReady) {
    [self.customEventInterstitial presentFromRootViewController:self];
  }
}

- (IBAction)showAdapterInterstitial:(UIButton *)sender {
  if (self.adapterInterstitial.isReady) {
    [self.adapterInterstitial presentFromRootViewController:self];
  }
}

- (void)replaceNativeAdView:(UIView *)nativeAdView inPlaceholder:(UIView *)placeholder {
  // Remove anything currently in the placeholder.
  NSArray *currentSubviews = [placeholder.subviews copy];
  for (UIView *subview in currentSubviews) {
    [subview removeFromSuperview];
  }

  if (!nativeAdView) {
    return;
  }

  // Add new ad view and set constraints to fill its container.
  [placeholder addSubview:nativeAdView];
  nativeAdView.translatesAutoresizingMaskIntoConstraints = NO;

  NSDictionary *viewDictionary = NSDictionaryOfVariableBindings(nativeAdView);
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[nativeAdView]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:viewDictionary]];
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[nativeAdView]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:viewDictionary]];
}

#pragma mark GADInterstitialDelegate implementation

- (void)interstitial:(GADInterstitial *)interstitial
    didFailToReceiveAdWithError:(GADRequestError *)error {
  if (interstitial == self.customEventInterstitial) {
    NSLog(@"Custom Event Interstitial failed to load with error code %@.",
          error.localizedDescription);
  } else if (interstitial == self.adapterInterstitial) {
    NSLog(@"Adapter Interstitial failed to load with error code %@.", error.localizedDescription);
  }
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial {
  if (interstitial == self.customEventInterstitial) {
    [self requestCustomEventInterstitial];
  } else if (interstitial == self.adapterInterstitial) {
    [self requestAdapterInterstitial];
  }
}

#pragma mark GADAdLoaderDelegate implementation

- (void)adLoader:(GADAdLoader *)adLoader didFailToReceiveAdWithError:(GADRequestError *)error {
  NSLog(@"%@ failed with error: %@", adLoader, error.localizedDescription);
}

#pragma mark GADNativeAppInstallAdLoaderDelegate implementation

- (void)adLoader:(GADAdLoader *)adLoader
    didReceiveNativeAppInstallAd:(GADNativeAppInstallAd *)nativeAppInstallAd {
  NSLog(@"Received native app install ad: %@", nativeAppInstallAd);

  // Create and place ad in view hierarchy.
  NSArray *nibLoadResult =
      [[NSBundle mainBundle] loadNibNamed:@"ExampleNativeAppInstallAdView" owner:nil options:nil];
  ExampleNativeAppInstallAdView *appInstallAdView = nibLoadResult.firstObject;

  // The adapter and custom event have their own placeholders and keys for the extra field.
  UIView *placeholder = nil;
  NSString *awesomenessKey = nil;

  if (adLoader == self.customEventAdLoader) {
    placeholder = self.customEventNativeAdPlaceholder;
    awesomenessKey = SampleCustomEventExtraKeyAwesomeness;
  } else {
    placeholder = self.adapterNativeAdPlaceholder;
    awesomenessKey = SampleAdapterExtraKeyAwesomeness;
  }

  [self replaceNativeAdView:appInstallAdView inPlaceholder:placeholder];

  // Associate the app install ad view with the app install ad object. This is required to make the
  // ad clickable.
  appInstallAdView.nativeAppInstallAd = nativeAppInstallAd;

  // Populate the app install ad view with the app install ad assets.
  // Some assets are guaranteed to be present in every app install ad.
  ((UILabel *)appInstallAdView.headlineView).text = nativeAppInstallAd.headline;
  ((UIImageView *)appInstallAdView.iconView).image = nativeAppInstallAd.icon.image;
  ((UILabel *)appInstallAdView.bodyView).text = nativeAppInstallAd.body;
  ((UIImageView *)appInstallAdView.imageView).image =
      ((GADNativeAdImage *)[nativeAppInstallAd.images firstObject]).image;
  [((UIButton *)appInstallAdView.callToActionView)setTitle:nativeAppInstallAd.callToAction
                                                  forState:UIControlStateNormal];

  // Other assets are not, however, and should be checked first.
  if (nativeAppInstallAd.starRating) {
    ((UIImageView *)appInstallAdView.starRatingView).image =
        [self imageForStars:nativeAppInstallAd.starRating];
    appInstallAdView.starRatingView.hidden = NO;
  } else {
    appInstallAdView.starRatingView.hidden = YES;
  }

  if (nativeAppInstallAd.store) {
    ((UILabel *)appInstallAdView.storeView).text = nativeAppInstallAd.store;
    appInstallAdView.storeView.hidden = NO;
  } else {
    appInstallAdView.storeView.hidden = YES;
  }

  if (nativeAppInstallAd.price) {
    ((UILabel *)appInstallAdView.priceView).text = nativeAppInstallAd.price;
    appInstallAdView.priceView.hidden = NO;
  } else {
    appInstallAdView.priceView.hidden = YES;
  }

  // If the ad came from the Sample SDK, it should contain an extra asset, which is retrieved here.
  NSString *degreeOfAwesomeness = nativeAppInstallAd.extraAssets[awesomenessKey];

  if (degreeOfAwesomeness) {
    appInstallAdView.degreeOfAwesomenessView.text = degreeOfAwesomeness;
    appInstallAdView.degreeOfAwesomenessView.hidden = NO;
  } else {
    appInstallAdView.degreeOfAwesomenessView.hidden = YES;
  }

  // In order for the SDK to process touch events properly, user interaction should be disabled.
  appInstallAdView.callToActionView.userInteractionEnabled = NO;
}

/// Gets an image representing the number of stars. Returns nil if rating is less than 3.5 stars.
- (UIImage *)imageForStars:(NSDecimalNumber *)numberOfStars {
  double starRating = numberOfStars.doubleValue;
  if (starRating >= 5) {
    return [UIImage imageNamed:@"stars_5"];
  } else if (starRating >= 4.5) {
    return [UIImage imageNamed:@"stars_4_5"];
  } else if (starRating >= 4) {
    return [UIImage imageNamed:@"stars_4"];
  } else if (starRating >= 3.5) {
    return [UIImage imageNamed:@"stars_3_5"];
  } else {
    return nil;
  }
}

#pragma mark GADNativeContentAdLoaderDelegate implementation

- (void)adLoader:(GADAdLoader *)adLoader
    didReceiveNativeContentAd:(GADNativeContentAd *)nativeContentAd {
  NSLog(@"Received native content ad: %@", nativeContentAd);

  // Create and place ad in view hierarchy.
  NSArray *nibLoadResult =
      [[NSBundle mainBundle] loadNibNamed:@"ExampleNativeContentAdView" owner:nil options:nil];
  ExampleNativeContentAdView *contentAdView = nibLoadResult.firstObject;

  // The adapter and custom event have their own placeholders and keys for the extra field.
  UIView *placeholder = nil;
  NSString *awesomenessKey = nil;

  if (adLoader == self.customEventAdLoader) {
    placeholder = self.customEventNativeAdPlaceholder;
    awesomenessKey = SampleCustomEventExtraKeyAwesomeness;
  } else {
    placeholder = self.adapterNativeAdPlaceholder;
    awesomenessKey = SampleAdapterExtraKeyAwesomeness;
  }

  [self replaceNativeAdView:contentAdView inPlaceholder:placeholder];

  // Associate the content ad view with the content ad object. This is required to make the ad
  // clickable.
  contentAdView.nativeContentAd = nativeContentAd;

  // Populate the content ad view with the content ad assets.
  // Some assets are guaranteed to be present in every content ad.
  ((UILabel *)contentAdView.headlineView).text = nativeContentAd.headline;
  ((UILabel *)contentAdView.bodyView).text = nativeContentAd.body;
  ((UIImageView *)contentAdView.imageView).image =
      ((GADNativeAdImage *)[nativeContentAd.images firstObject]).image;
  ((UILabel *)contentAdView.advertiserView).text = nativeContentAd.advertiser;
  [((UIButton *)contentAdView.callToActionView)setTitle:nativeContentAd.callToAction
                                               forState:UIControlStateNormal];

  // Other assets are not, however, and should be checked first.
  if (nativeContentAd.logo && nativeContentAd.logo.image) {
    ((UIImageView *)contentAdView.logoView).image = nativeContentAd.logo.image;
    contentAdView.logoView.hidden = NO;
  } else {
    contentAdView.logoView.hidden = YES;
  }

  // If the ad came from the Sample SDK, it should contain an extra asset, which is retrieved here.
  NSString *degreeOfAwesomeness = nativeContentAd.extraAssets[awesomenessKey];

  if (degreeOfAwesomeness) {
    contentAdView.degreeOfAwesomenessView.text = degreeOfAwesomeness;
    contentAdView.degreeOfAwesomenessView.hidden = NO;
  } else {
    contentAdView.degreeOfAwesomenessView.hidden = YES;
  }

  // In order for the SDK to process touch events properly, user interaction should be disabled.
  contentAdView.callToActionView.userInteractionEnabled = NO;
}

@end
