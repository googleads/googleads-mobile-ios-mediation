//
//  GADMAdapterPangleUtils.h
//  PangleAdpter
//
//  Created by bytedance on 2021/12/16.
//

#import "GADMediationAdapterPangle.h"

#define PangleLog(format, args...)    NSLog(@"PangleAdaper | "format,##args)

NSError *_Nonnull GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorCode code,
                                                                 NSString *_Nonnull description);
