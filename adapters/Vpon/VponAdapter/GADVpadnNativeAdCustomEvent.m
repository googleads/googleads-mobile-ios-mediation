//
//  GADVpadnNativeAdCustomEvent.m
//  VponAdapter
//
//  Created by EricChien on 2018/10/24.
//  Copyright © 2018 Vpon. All rights reserved.
//

#import "GADVpadnNativeAdCustomEvent.h"
#import "GADVpadnNativeAd.h"
#import "GADVpadnDefinition.h"

#define VP_CONTENT_URL @"contentURL"
#define VP_CONTENT_DATA @"contentData"

#define VP_CONTENT_FRIENDLY_OBS @"friendlyObstructions"
#define VP_CONTENT_FRIENDLY_VIEW @"view"
#define VP_CONTENT_FRIENDLY_PURPOSE @"purpose"
#define VP_CONTENT_FRIENDLY_DESC @"desc"

@interface GADVpadnNativeAdCustomEvent () <GADCustomEventNativeAd, GADCustomEventNativeAdDelegate, VpadnNativeAdDelegate, GADVpadnNativeAdDelegate> {
    GADNativeAdViewAdOptions *_nativeAdViewAdOptions;
}

@property (strong, nonatomic) VpadnNativeAd *nativeAd;

@property (strong, nonatomic) GADVpadnNativeAd *mediatedAd;

@end

@implementation GADVpadnNativeAdCustomEvent

@synthesize delegate;

- (BOOL)handlesUserClicks {
    return YES;
}

- (BOOL)handlesUserImpressions {
    return YES;
}

#pragma mark - GADCustomEventNativeAd Protocol

- (void)requestNativeAdWithParameter:(NSString *)serverParameter
                             request:(GADCustomEventRequest *)request
                             adTypes:(NSArray *)adTypes
                             options:(NSArray *)options
                  rootViewController:(UIViewController *)rootViewController {
    [GADVpadnDefinition adapterNote];
    if ([GADVpadnDefinition verifyVersion] == NO) {
        [self customEventNativeAd:self didFailToLoadWithError:[GADVpadnDefinition defaultError]];
        return;
    } else {
        __block __weak typeof(self) weakSelf = self;
        dispatch_queue_t serialQueue = dispatch_queue_create("com.vpon.na.queue", DISPATCH_QUEUE_SERIAL);
        dispatch_async(serialQueue, ^{
            if (weakSelf.nativeAd) {
                [weakSelf.nativeAd unregisterView];
            }
            weakSelf.nativeAd = [[VpadnNativeAd alloc] initWithLicenseKey:serverParameter];
            weakSelf.nativeAd.delegate = weakSelf;
            [weakSelf.nativeAd loadRequest:[weakSelf createRequest:request]];
        });
    }
}

- (VpadnAdRequest *) createRequest:(GADCustomEventRequest *)request {
    VpadnAdRequest *vprequest = [[VpadnAdRequest alloc] init];
    [vprequest setTestDevices:@[]];
    if (request.additionalParameters) {
        if ([vprequest respondsToSelector:@selector(setContentData:)] &&
            [request.additionalParameters.allKeys containsObject:VP_CONTENT_DATA] &&
            [request.additionalParameters[VP_CONTENT_DATA] isKindOfClass:[NSDictionary class]]) {
            [vprequest setContentData:request.additionalParameters[VP_CONTENT_DATA]];
        }
        if ([vprequest respondsToSelector:@selector(setContentUrl:)] &&
            [request.additionalParameters.allKeys containsObject:VP_CONTENT_URL] &&
            [request.additionalParameters[VP_CONTENT_URL] isKindOfClass:[NSString class]]) {
            [vprequest setContentUrl:request.additionalParameters[VP_CONTENT_URL]];
        }
        if ([vprequest respondsToSelector:@selector(addFriendlyObstruction:purpose:description:)] &&
            [request.additionalParameters.allKeys containsObject:VP_CONTENT_FRIENDLY_OBS] &&
            [request.additionalParameters[VP_CONTENT_FRIENDLY_OBS] isKindOfClass:[NSArray class]]) {
            NSArray *friendlyObstructions = request.additionalParameters[VP_CONTENT_FRIENDLY_OBS];
            for (NSDictionary *friendlyObstruction in friendlyObstructions) {
                if (![friendlyObstruction isKindOfClass:NSDictionary.class]) continue;
                if (![friendlyObstruction[VP_CONTENT_FRIENDLY_VIEW] isKindOfClass:UIView.class]) continue;
                UIView *view = friendlyObstruction[VP_CONTENT_FRIENDLY_VIEW];
                NSString *desc = [friendlyObstruction[VP_CONTENT_FRIENDLY_DESC] isKindOfClass:NSString.class] ? friendlyObstruction[VP_CONTENT_FRIENDLY_DESC] : @"";
                VpadnFriendlyObstructionType purpose = VpadnFriendlyObstructionOther;
                if ([friendlyObstruction.allKeys containsObject:VP_CONTENT_FRIENDLY_PURPOSE]) {
                    purpose = [VpadnAdObstruction getVpadnPurpose:[friendlyObstruction[VP_CONTENT_FRIENDLY_PURPOSE] integerValue]];
                }
                [vprequest addFriendlyObstruction:view purpose:purpose description:desc];
            }
        }
    }
    for (NSString *keyword in request.userKeywords) {
        [vprequest addKeyword:keyword];
    }
    return vprequest;
}

#pragma mark - VpadnNativeAd Delegate

- (void) onVpadnNativeAdLoaded:(VpadnNativeAd *)nativeAd {
    _mediatedAd = [[GADVpadnNativeAd alloc] initWithNativeAd:nativeAd adOptions:_nativeAdViewAdOptions delegate:self];
    [_mediatedAd loadImages];
}

- (void) onVpadnNativeAd:(VpadnNativeAd *)nativeAd failedToLoad:(NSError *)error {
    [self customEventNativeAd:self didFailToLoadWithError:error];
}

- (void) onVpadnNativeAdDidImpression:(VpadnNativeAd *)nativeAd {
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordImpression:_mediatedAd];
}

- (void) onVpadnNativeAdClicked:(VpadnNativeAd *)nativeAd {
    [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordClick:_mediatedAd];
}

#pragma mark -

-(void) onGADVpadnNativeAdDidImageLoaded:(GADVpadnNativeAd *)mediatedAd {
    [self customEventNativeAd:self didReceiveMediatedUnifiedNativeAd:mediatedAd];
}

#pragma mark - GADCustomEventNativeAd Delegate

- (void)customEventNativeAd:(nonnull id<GADCustomEventNativeAd>)customEventNativeAd didFailToLoadWithError:(nonnull NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(customEventNativeAd:didFailToLoadWithError:)]) {
        [self.delegate customEventNativeAd:customEventNativeAd didFailToLoadWithError:error];
    }
}

- (void)customEventNativeAd:(nonnull id<GADCustomEventNativeAd>)customEventNativeAd didReceiveMediatedUnifiedNativeAd:(nonnull id<GADMediatedUnifiedNativeAd>)mediatedUnifiedNativeAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(customEventNativeAd:didReceiveMediatedUnifiedNativeAd:)]) {
        [self.delegate customEventNativeAd:customEventNativeAd didReceiveMediatedUnifiedNativeAd:mediatedUnifiedNativeAd];
    }
}

@end
