//
//  GADMAdapterMyTargetConstants.h
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 28.09.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

static NSString *const kGADMAdapterMyTargetVersion = @"5.0.4.0";
static NSString *const kGADMAdapterMyTargetSlotIdKey = @"slotId";
static NSString *const kGADMAdapterMyTargetGenderKey = @"gender";
static NSString *const kGADMAdapterMyTargetBirthdayKey = @"birthday";
static NSString *const kGADMAdapterMyTargetNativeAdTypeKey = @"at";
static NSString *const kGADMAdapterMyTargetNativeAdTypeInstall = @"1";
static NSString *const kGADMAdapterMyTargetNativeAdTypeContent = @"2";
static NSString *const kGADMAdapterMyTargetErrorDomain =
    @"com.my.target.sdk.mediation.admob.errorDomain";
static NSString *const kGADMAdapterMyTargetErrorSlotId = @"Invalid credentials: slotId not found";
static NSString *const kGADMAdapterMyTargetErrorNoAd = @"No ad";
static NSString *const kGADMAdapterMyTargetErrorMediatedAdInvalid =
    @"Some of the Always Included assets are not available for the ad";
static NSString *const kGADMAdapterMyTargetErrorMediatedAdDoesNotMatch =
    @"Mediated NativeAd [%@] doesn't match reqeusted type (%@)";
static NSString *const kGADMAdapterMyTargetErrorBannersNotSupported =
    @"Banners are not supported by this adapter";
static NSString *const kGADMAdapterMyTargetErrorInterstitialNotSupported =
    @"Interstitial ads are not supported by this adapter";
static NSString *const kGADMAdapterMyTargetErrorInvalidNativeAdType = @"Invalid NativeAd type (%@)";
static NSString *const kGADMAdapterMyTargetErrorInvalidSize = @"Size not supported";
