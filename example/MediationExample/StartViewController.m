//
// Copyright (C) 2017 Google, Inc.
//
// StartViewController.m
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

#import "StartViewController.h"
#import "ViewController.h"

typedef enum : NSUInteger {
  CellIndexSampleAdSDK = 0,
  CellIndexObjC,
  CellIndexSwift,
} CellIndex;

@interface StartViewController ()

@end

@implementation StartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  switch (indexPath.row) {
    case CellIndexSampleAdSDK:
      [self launchViewControllerOfType:AdSourceTypeAdapter];
      break;
    case CellIndexObjC:
      [self launchViewControllerOfType:AdSourceTypeCustomEventObjC];
      break;
    case CellIndexSwift:
      [self launchViewControllerOfType:AdSourceTypeCustomEventSwift];
      break;
    default:
      break;
  }
}

- (void)launchViewControllerOfType:(AdSourceType)adSourceType {
  AdSourceConfig *config = [AdSourceConfig configWithType:adSourceType];
  ViewController *controller = [ViewController controllerWithAdSourceConfig:config];
  [self.navigationController pushViewController:controller animated:YES];
}


@end
