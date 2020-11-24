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
  return [self errorWithDescription:description errorCode:0];
}

+ (NSError *)errorWithDescription:(NSString *)description errorCode:(NSInteger)errorCode {
  description = [description copy];
  NSDictionary *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:kGADMMaioErrorDomain code:errorCode userInfo:userInfo];
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
    case MaioFailReasonNotFoundViewContext:
      return @"NotFoundViewContext";
  }
}
+ (NSString *)stringFromErrorCode:(NSInteger)errorCode {
  if ([self codeIsAboutLoad:errorCode]) {
    return @"Error is about Load.";
  }
  if ([self codeIsAboutShow:errorCode]) {
    return @"Error is about Show.";
  }
  return @"Unknown Error";
}

+ (BOOL)codeIsAboutLoad:(NSInteger)errorCode {
  return errorCode >= 10000 && errorCode < 20000;
}

+ (BOOL)codeIsAboutShow:(NSInteger)errorCode {
  return errorCode >= 20000 && errorCode < 30000;
}

@end
