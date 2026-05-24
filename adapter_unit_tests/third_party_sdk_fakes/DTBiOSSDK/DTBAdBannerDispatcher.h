#import <UIKit/UIKit.h>

@protocol DTBAdBannerDispatcherDelegate <NSObject>
- (void)adDidLoad:(nonnull UIView *)adView;
- (void)adFailedToLoad:(nullable UIView *)banner errorCode:(NSInteger)errorCode;
- (void)bannerWillLeaveApplication:(nonnull UIView *)adView;
- (void)impressionFired;
@optional
- (void)adClicked;
@end

@interface DTBAdBannerDispatcher : NSObject
- (instancetype)initWithAdFrame:(CGRect)frame delegate:(id<DTBAdBannerDispatcherDelegate>)delegate;
- (void)fetchBannerAd:(nonnull NSString *)htmlString;
@end
