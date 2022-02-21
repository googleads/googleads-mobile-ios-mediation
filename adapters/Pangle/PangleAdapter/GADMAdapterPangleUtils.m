//
//  GADMAdapterPangleUtils.m
//  PangleAdpter
//
//  Created by bytedance on 2021/12/16.
//

#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"

NSError *_Nonnull GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorCode code,
                                                               NSString *_Nonnull description) {
    return [NSError errorWithDomain:GADMAdapterPangleErrorDomain code:code userInfo:@{
        NSLocalizedDescriptionKey : description,
        NSLocalizedFailureReasonErrorKey : description
    }];
}
