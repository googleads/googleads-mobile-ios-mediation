//
// Copyright 2019 Google LLC
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

#import "SampleRewardedAdController.h"

@interface SampleRewardedAdController () {
  /// Clock label to show count.
  UILabel *_clockLabel;

  /// Close button to close ad.
  UIButton *_closeButton;

  /// Count down counter for timer.
  int _counter;

  /// Sample rewarded ad.
  SampleRewardedAd *_rewardedAd;
}

@end

@implementation SampleRewardedAdController

- (instancetype)initWithRewardedAd:(SampleRewardedAd *)rewardedAd {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _rewardedAd = rewardedAd;
  }

  return self;
}

- (void)viewDidLoad {
  _clockLabel = [[UILabel alloc] initWithFrame:CGRectMake(50.0f, 50.0f, 50.0f, 50.0f)];
  _clockLabel.backgroundColor = [UIColor whiteColor];
  _clockLabel.textColor = [UIColor blackColor];
  [self.view addSubview:_clockLabel];
  _clockLabel.translatesAutoresizingMaskIntoConstraints = NO;
  NSDictionary *viewDictionary = NSDictionaryOfVariableBindings(_clockLabel);
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_clockLabel]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:viewDictionary]];
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_clockLabel]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:viewDictionary]];

  _closeButton = [[UIButton alloc] initWithFrame:CGRectMake(250, 250, 250, 250)];
  [_closeButton setTitle:@"X" forState:UIControlStateNormal];
  _closeButton.backgroundColor = [UIColor blackColor];
  _closeButton.titleLabel.textColor = [UIColor whiteColor];
  [_closeButton addTarget:self
                   action:@selector(closeAd:)
         forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:_closeButton];
  NSDictionary *views = NSDictionaryOfVariableBindings(_closeButton);
  _closeButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_closeButton(60)]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:views]];
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_closeButton(60)]"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:views]];
  _closeButton.hidden = YES;

  [self startCountdown];
}

- (void)viewDidAppear:(BOOL)animated {
  id<SampleRewardedAdDelegate> strongDelegate = self.delegate;
  if ([strongDelegate respondsToSelector:@selector(rewardedAdDidPresent:)]) {
    [strongDelegate rewardedAdDidPresent:_rewardedAd];
  }
}

/// Starts the count down timer with 10 seconds.
- (void)startCountdown {
  _counter = 10;
  [NSTimer scheduledTimerWithTimeInterval:1
                                   target:self
                                 selector:@selector(countdownTimer:)
                                 userInfo:nil
                                  repeats:YES];
}

/// Timer Count down for 10 seconds. Once the counter reaches to 0, then the timer invalidates and
/// calls the handleCountdownFinished method.
- (void)countdownTimer:(NSTimer *)timer {
  _counter--;
  _clockLabel.text = [NSString stringWithFormat:@"%d", _counter];
  if (_counter <= 0) {
    [timer invalidate];
    _closeButton.hidden = NO;
    [self handleCountdownFinished];
  }
}

/// On completion (video ad), tells the delegate that user gets reward amount/coins.
- (void)handleCountdownFinished {
  _clockLabel.text = [NSString
      stringWithFormat:@"Rewarded with reward amount %lu", (unsigned long)_rewardedAd.reward];
  id<SampleRewardedAdDelegate> strongDelegate = self.delegate;
  if ([strongDelegate respondsToSelector:@selector(rewardedAd:userDidEarnReward:)]) {
    [strongDelegate rewardedAd:_rewardedAd userDidEarnReward:_rewardedAd.reward];
  }
  UITapGestureRecognizer *tapGestureRecognizer =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
  [self.view addGestureRecognizer:tapGestureRecognizer];
}

/// Closes the ad and tells the delegate that reward-based video ad closed.
- (void)closeAd:(id)sender {
  id<SampleRewardedAdDelegate> strongDelegate = self.delegate;
  if ([strongDelegate respondsToSelector:@selector(rewardedAdDidDismiss:)]) {
    [strongDelegate rewardedAdDidDismiss:_rewardedAd];
  }

  [self dismissViewControllerAnimated:YES completion:nil];
}

/// Handles the tap on ad, and tells the delegate that ad gets clicked.
- (void)handleTap:(UITapGestureRecognizer *)recognizer {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.google.com"]];
}

@end
