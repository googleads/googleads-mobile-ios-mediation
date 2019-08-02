//
//  GADMAdapterChartboostBanner.m
//  Adapter
//
//  Created by Daniel Barros on 17/07/2019.
//  Copyright © 2019 Google. All rights reserved.
//

#import "GADMAdapterChartboostBanner.h"

@interface GADMAdapterChartboostBanner () <CHBBannerDelegate>

@property (nonatomic) NSMapTable<CHBBanner *, id<CHBBannerDelegate>> *bannersToDelegates;
@property (nonatomic) NSMutableArray<CHBBanner *> *loadingBanners;

@end

@implementation GADMAdapterChartboostBanner

+ (instancetype)sharedInstance
{
    static GADMAdapterChartboostBanner *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _bannersToDelegates = [NSMapTable weakToWeakObjectsMapTable];
        _loadingBanners = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)loadBannerWithSize:(GADAdSize)adSize
                  location:(nonnull NSString *)location
                  delegate:(nullable id<CHBBannerDelegate>)delegate
            viewController:(nullable UIViewController *)viewController
                    extras:(nullable GADMChartboostExtras *)extras
{
    if (extras.frameworkVersion && extras.framework) {
        [Chartboost setFramework:extras.framework withVersion:extras.frameworkVersion];
    }
    CHBBanner *banner = [[CHBBanner alloc] initWithSize:adSize.size location:location delegate:self];
    banner.automaticallyRefreshesContent = NO;
    [self.loadingBanners addObject:banner];
    [self.bannersToDelegates setObject:delegate forKey:banner];
    [banner showFromViewController:viewController];
}

#pragma mark - CHBBannerDelegate

- (void)didCacheAd:(CHBCacheEvent *)event error:(nullable CHBCacheError *)error
{
    // We keep a strong reference to the banner only until it is loaded, since at that point the view is sent to GMA (as a parameter in a delegate call) and it is its responsibility to retain it.
    [[self.bannersToDelegates objectForKey:(CHBBanner *)event.ad] didCacheAd:event error:error];
    [self.loadingBanners removeObject:(CHBBanner *)event.ad];
}

- (void)willShowAd:(CHBShowEvent *)event error:(nullable CHBShowError *)error
{
    [[self.bannersToDelegates objectForKey:(CHBBanner *)event.ad] willShowAd:event error:error];
}

- (void)didShowAd:(CHBShowEvent *)event error:(nullable CHBShowError *)error
{
    [[self.bannersToDelegates objectForKey:(CHBBanner *)event.ad] didShowAd:event error:error];
}

- (void)didClickAd:(CHBClickEvent *)event error:(nullable CHBClickError *)error
{
    [[self.bannersToDelegates objectForKey:(CHBBanner *)event.ad] didClickAd:event error:error];
}

- (void)didFinishHandlingClick:(CHBClickEvent *)event error:(nullable CHBClickError *)error
{
    [[self.bannersToDelegates objectForKey:(CHBBanner *)event.ad] didFinishHandlingClick:event error:error];
}

@end
