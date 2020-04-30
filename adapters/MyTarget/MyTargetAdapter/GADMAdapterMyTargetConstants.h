//
//  GADMAdapterMyTargetConstants.h
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 28.09.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

static NSString *const _Nonnull kGADMAdapterMyTargetVersion = @"5.4.9.0";
static NSString *const _Nonnull kGADMAdapterMyTargetSlotIdKey = @"slotId";
static NSString *const _Nonnull kGADMAdapterMyTargetGenderKey = @"gender";
static NSString *const _Nonnull kGADMAdapterMyTargetBirthdayKey = @"birthday";
static NSString *const _Nonnull kGADMAdapterMyTargetNativeAdTypeKey = @"at";
static NSString *const _Nonnull kGADMAdapterMyTargetNativeAdTypeInstall = @"1";
static NSString *const _Nonnull kGADMAdapterMyTargetNativeAdTypeContent = @"2";
static NSString *const _Nonnull kGADMAdapterMyTargetErrorDomain =
    @"com.my.target.sdk.mediation.admob.errorDomain";
static NSString *const _Nonnull kGADMAdapterMyTargetErrorSlotId =
    @"Invalid credentials: slotId not found";
static NSString *const _Nonnull kGADMAdapterMyTargetErrorNoAd = @"No ad";
static NSString *const _Nonnull kGADMAdapterMyTargetErrorMediatedAdInvalid =
    @"Some of the Always Included assets are not available for the ad";
static NSString *const _Nonnull kGADMAdapterMyTargetErrorMediatedAdDoesNotMatch =
    @"Mediated NativeAd [%@] doesn't match reqeusted type (%@)";
static NSString *const _Nonnull kGADMAdapterMyTargetErrorBannersNotSupported =
    @"Banners are not supported by this adapter";
static NSString *const _Nonnull kGADMAdapterMyTargetErrorInterstitialNotSupported =
    @"Interstitial ads are not supported by this adapter";
static NSString *const _Nonnull kGADMAdapterMyTargetErrorInvalidNativeAdType =
    @"Invalid NativeAd type (%@)";
static NSString *const _Nonnull kGADMAdapterMyTargetErrorInvalidSize = @"Size not supported";
