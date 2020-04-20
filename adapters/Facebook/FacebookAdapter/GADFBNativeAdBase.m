// Copyright 2019 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADFBNativeAdBase.h"
#import "GADFBNativeBannerAd.h"
#import "GADFBNetworkExtras.h"
#import "GADFBUnifiedNativeAd.h"

@implementation GADFBNativeAdBase {
  /// Connector from the Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// Facebook adapter network extras.
  GADFBNetworkExtras *_extras;
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                               adapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;
    _extras = connector.networkExtras;
  }
  return self;
}

- (nullable UIView *)adChoicesView {
  return _adOptionsView;
}

- (nullable NSDecimalNumber *)starRating {
  return nil;
}

- (nullable NSString *)store {
  return nil;
}

- (nullable NSString *)price {
  return nil;
}

- (nullable NSArray *)images {
  return nil;
}

- (nullable GADNativeAdImage *)icon {
  /// Creates a 1 x 1 transparent image which acts as a placeholder image until the Facebook
  /// Audience Network SDK renders the icon view.
  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(1, 1)];
  UIImage *image =
      [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext){
      }];
  return [[GADNativeAdImage alloc] initWithImage:image];
}

- (void)loadAdOptionsView {
  if (_adOptionsView) {
    return;
  }

  _adOptionsView = [[FBAdOptionsView alloc] init];
  _adOptionsView.backgroundColor = UIColor.clearColor;
  [NSLayoutConstraint activateConstraints:@[
    [_adOptionsView.heightAnchor constraintEqualToConstant:FBAdOptionsViewHeight],
    [_adOptionsView.widthAnchor constraintEqualToConstant:FBAdOptionsViewWidth],
  ]];
}

@end
