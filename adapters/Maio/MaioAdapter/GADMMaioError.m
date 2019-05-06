//
//  GADMMaioError.m
//  GADMMaioAdapter
//
//  Copyright © 2017 i-mobile, Inc. All rights reserved.
//

#import "GADMMaioError.h"
#import "GADMMaioConstants.h"

@implementation GADMMaioError

+ (NSError *)errorWithDescription:(NSString *)description {
  description = [description copy];
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:kGADMMaioErrorDomain code:0 userInfo:userInfo];
  return error;
}

/**
 *  MaioFailReason の文字列表記を取得します。
 */
+ (NSString *)stringFromFailReason:(MaioFailReason)failReason {
  switch (failReason) {
    case MaioFailReasonUnknown:
      return @"Unknown";
    case MaioFailReasonNetworkConnection:
      return @"NetworkConnection";
    case MaioFailReasonNetworkServer:
      return @"NetworkServer";
    case MaioFailReasonNetworkClient:
      return @"NetworkClient";
    case MaioFailReasonSdk:
      return @"Sdk";
    case MaioFailReasonDownloadCancelled:
      return @"DownloadCancelled";
    case MaioFailReasonAdStockOut:
      return @"AdStockOut";
    case MaioFailReasonVideoPlayback:
      return @"VideoPlayback";
    case MaioFailReasonIncorrectMediaId:
      return @"InCorrectMediaId";
    case MaioFailReasonIncorrectZoneId:
      return @"InCorrectZoneId";
  }
}

@end
