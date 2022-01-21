//
//  GADMAdapterPangleUtils.h
//  PangleAdpter
//
//  Created by bytedance on 2021/12/16.
//

#import <Foundation/Foundation.h>
#import "GADMediationAdapterPangle.h"

NS_ASSUME_NONNULL_BEGIN

#define PangleLog(format, args...)    NSLog(@"PangleAdaper:"format,##args)
#define PangleIsEmptyString(string)   (!string || ![string isKindOfClass:[NSString class]] || string.length == 0)

NSError *_Nonnull GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorCode code,
                                                                 NSString *_Nonnull description);

@interface GADMAdapterPangleUtils : NSObject

@end

NS_ASSUME_NONNULL_END
