//
// Copyright (C) 2015 Google, Inc.
//
// SampleMediaView.m
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

#import "SampleMediaView.h"
#import <UIKit/UIKit.h>
#import "SampleNativeAd.h"

@interface SampleMediaView ()
@property(nonatomic, strong) UILabel* label;
@end
@implementation SampleMediaView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.frame = frame;
  }
  return self;
}

- (void)createMediaContent {
  _label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  _label.backgroundColor = [UIColor colorWithRed:0 green:0.8 blue:0 alpha:1];
  _label.text = @"Sample video";
  _label.textAlignment = NSTextAlignmentCenter;
  _label.autoresizingMask =
      UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewContentModeCenter;
  [self addSubview:_label];
  self.clipsToBounds = YES;
}

- (void)playMedia {
  int timer = 10;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timer / 6 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   _label.text = @"20% loaded";
                 });
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timer / 4 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   _label.text = @"40% loaded";
                 });
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timer / 3 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   _label.text = @"60% loaded";
                 });

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timer / 2 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   _label.text = @"100% loaded";
                 });
}

@end
