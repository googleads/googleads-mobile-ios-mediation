//
// Copyright (C) 2015 Google, Inc.
//
// SampleBannner.m
// Sample Ad Network SDK
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

#import "SampleAdRequest.h"

#import "SampleBanner.h"

@implementation SampleBanner

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self sharedInitialization];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self sharedInitialization];
  }
  return self;
}

- (void)sharedInitialization {
  self.userInteractionEnabled = NO;
  UITapGestureRecognizer *tapGesture =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(labelTap:)];
  [self addGestureRecognizer:tapGesture];
  self.textColor = [UIColor blackColor];
  self.backgroundColor = [UIColor lightGrayColor];
  self.textAlignment = NSTextAlignmentCenter;
  [self layoutIfNeeded];
}

- (void)fetchAd:(SampleAdRequest *)request {
  NSLog(@"Fetching ad");

  if (!self.adUnit) {
    [self.delegate banner:self didFailToLoadAdWithErrorCode:SampleErrorCodeBadRequest];
    return;
  }

  // Randomly decide whether to succeed or fail.
  int randomValue = arc4random_uniform(100);
  NSLog(@"Random int: %d", randomValue);

  NSString *options = @"";

  if (randomValue < 85) {
    if (request.testMode) {
      options = @"in test mode ";
    }
    if (request.keywords) {
      options = [options stringByAppendingString:@"with keywords: "];
      options = [options stringByAppendingString:[request.keywords componentsJoinedByString:@", "]];
    }

    self.text = [@"Sample Text Ad " stringByAppendingString:options];
    self.userInteractionEnabled = YES;
    [self.delegate bannerDidLoad:self];
  } else if (randomValue < 90) {
    [self.delegate banner:self didFailToLoadAdWithErrorCode:SampleErrorCodeUnknown];
  } else if (randomValue < 95) {
    [self.delegate banner:self didFailToLoadAdWithErrorCode:SampleErrorCodeNetworkError];
  } else {
    [self.delegate banner:self didFailToLoadAdWithErrorCode:SampleErrorCodeNoInventory];
  }
  NSLog(@"Done fetching ad");
}

- (void)labelTap:(UIGestureRecognizer *)tapGesture {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.google.com"]];
  [self.delegate bannerWillLeaveApplication:self];
}

@end
