// Copyright 2025 Google LLC
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

#import "SampleAppOpenAdController.h"

@interface SampleAppOpenAdController () {
  /// Clock label to show count.
  UILabel *_clockLabel;

  /// Close button to close ad.
  UIButton *_closeButton;

  /// Count down counter for timer.
  int _counter;

  /// Sample app open ad.
  SampleAppOpenAd *_appOpenAd;
}

@end

@implementation SampleAppOpenAdController

- (nonnull instancetype)initWithAppOpenAd:(nonnull SampleAppOpenAd *)appOpenAd {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _appOpenAd = appOpenAd;
  }

  return self;
}

- (void)viewDidLoad {
  self.view.backgroundColor = [UIColor whiteColor];

  _clockLabel = [[UILabel alloc] initWithFrame:CGRectMake(50.0f, 50.0f, 50.0f, 50.0f)];
  _clockLabel.backgroundColor = [UIColor whiteColor];
  _clockLabel.textColor = [UIColor blackColor];
  _clockLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:_clockLabel];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_clockLabel
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.view
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.0
                                                         constant:0.0f]];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_clockLabel
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.view
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1.0
                                                         constant:0.0f]];

  _closeButton = [[UIButton alloc] initWithFrame:CGRectMake(250, 250, 250, 250)];
  [_closeButton setTitle:@"X" forState:UIControlStateNormal];
  _closeButton.backgroundColor = [UIColor blackColor];
  _closeButton.titleLabel.textColor = [UIColor whiteColor];
  [_closeButton addTarget:self
                   action:@selector(closeAd:)
         forControlEvents:UIControlEventTouchUpInside];
  _closeButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:_closeButton];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_closeButton
                                                        attribute:NSLayoutAttributeRight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.view
                                                        attribute:NSLayoutAttributeRight
                                                       multiplier:1.0
                                                         constant:0.0f]];
  [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_closeButton
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.view
                                                        attribute:NSLayoutAttributeTopMargin
                                                       multiplier:1.0
                                                         constant:0.0f]];
  _closeButton.hidden = YES;

  [self startCountdown];
}

- (void)viewDidAppear:(BOOL)animated {
  id<SampleAppOpenAdDelegate> strongDelegate = self.delegate;
  if ([strongDelegate respondsToSelector:@selector(appOpenAdDidPresent:)]) {
    [strongDelegate appOpenAdDidPresent:_appOpenAd];
  }
}

/// Starts the count down timer with 5 seconds.
- (void)startCountdown {
  _counter = 5;
  [NSTimer scheduledTimerWithTimeInterval:1
                                   target:self
                                 selector:@selector(countdownTimer:)
                                 userInfo:nil
                                  repeats:YES];
}

/// Timer Count down for 5 seconds. Once the counter reaches to 0, then the timer invalidates and
/// calls the handleCountdownFinished method.
- (void)countdownTimer:(NSTimer *)timer {
  _counter--;
  _clockLabel.text = [NSString stringWithFormat:@"%d", _counter];
  if (_counter <= 3) {
    _closeButton.hidden = NO;
  }
  if (_counter <= 0) {
    [timer invalidate];
    [self handleCountdownFinished];
  }
}

/// On completion, enable clicks.
- (void)handleCountdownFinished {
  _clockLabel.text = [NSString stringWithFormat:@"You may now close the ad."];

  UITapGestureRecognizer *tapGestureRecognizer =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
  [self.view addGestureRecognizer:tapGestureRecognizer];
}

/// Closes the ad and tells the delegate that the app open ad is closed.
- (void)closeAd:(id)sender {
  id<SampleAppOpenAdDelegate> strongDelegate = self.delegate;
  if ([strongDelegate respondsToSelector:@selector(appOpenAdDidDismiss:)]) {
    [strongDelegate appOpenAdDidDismiss:_appOpenAd];
  }

  [self dismissViewControllerAnimated:YES completion:nil];
}

/// Handles the tap on ad, and tells the delegate that ad gets clicked.
- (void)handleTap:(UITapGestureRecognizer *)recognizer {
  id<SampleAppOpenAdDelegate> strongDelegate = self.delegate;
  if ([strongDelegate respondsToSelector:@selector(appOpenAdDidDismiss:)]) {
    [strongDelegate appOpenWillLeaveApplication:_appOpenAd];
  }

  [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://www.google.com"]
                                   options:@{}
                         completionHandler:nil];
}

@end
