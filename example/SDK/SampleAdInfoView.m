//
// Copyright (C) 2016 Google, Inc.
//
// SampleAdInfoView.m
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

#import "SampleAdInfoView.h"

@implementation SampleAdInfoView

/// NS_DESIGNATED_INITIALIZER
- (instancetype)init {
  self = [super initWithFrame:CGRectMake(0, 0, 24.0, 24.0)];
  if (self) {
    [self createInfoImageView];
    self.backgroundColor = [UIColor clearColor];
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                           action:@selector(infoViewTapped)]];
  }

  return self;
}

/// Creates and adds info image in the view hierarchy.
- (void)createInfoImageView {
  UIImageView *infoImageView =
      [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"info_icon"]];
  [self addSubview:infoImageView];

  // Adding constraints to info image to cover the super view.
  NSDictionary *viewDictionary = NSDictionaryOfVariableBindings(infoImageView);
  infoImageView.translatesAutoresizingMaskIntoConstraints = NO;
  [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[infoImageView]|"
                                                               options:0
                                                               metrics:nil
                                                                 views:viewDictionary]];
  [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[infoImageView]|"
                                                               options:0
                                                               metrics:nil
                                                                 views:viewDictionary]];
}

/// Handles user tap on the view.
- (void)infoViewTapped {
  [[[UIAlertView alloc] initWithTitle:@"Sample SDK"
                              message:@"This is a sample ad from the Sample SDK"
                             delegate:nil
                    cancelButtonTitle:@"OK"
                    otherButtonTitles:nil, nil] show];
}

@end
