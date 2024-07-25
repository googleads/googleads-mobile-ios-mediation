#import <GoogleMobileAds/GoogleMobileAds.h>

/// Testable version of GADMediationCrendentials. It overrides properties with readonly attribute
/// with readwrite attribute.
@interface AUTKMediationCredentials : GADMediationCredentials

/// The AdMob UI settings.
@property(nonatomic, nonnull) NSDictionary<NSString *, id> *settings;

/// The ad format associated with the credentials.
@property(nonatomic) GADAdFormat format;

@end

/// Testable version of GADMediationServerConfiguration. It overrides properties with readonly
/// attribute with readwrite attribute.
@interface AUTKMediationServerConfiguration : GADMediationServerConfiguration

/// Array of mediation configurations set by the publisher on the AdMob UI. Each configuration is a
/// possible credential dictionary that the Google Mobile Ads SDK may provide at ad request time.
@property(nonatomic, nonnull) NSArray<GADMediationCredentials *> *credentials;

@end

/// Testable version of GADMediationAppOpenAdConfiguration. It overrides properties with readonly
/// attribute with readwrite attribute.
@interface AUTKMediationAppOpenAdConfiguration : GADMediationAppOpenAdConfiguration

/// The ad string returned from the 3PAS.
@property(nonatomic, nullable) NSString *bidResponse;

/// View controller to present from. This value must be read at presentation time to obtain the most
/// recent value. Must be accessed on the main queue.
@property(nonatomic, nullable) UIViewController *topViewController;

/// Mediation configuration set by the publisher on the AdMob frontend.
@property(nonatomic, nonnull) GADMediationCredentials *credentials;

/// PNG data containing a watermark that identifies the ad's source.
@property(nonatomic, nullable) NSData *watermark;

/// Extras the publisher registered with -[GADRequest registerAdNetworkExtras:].
@property(nonatomic, nullable) id<GADAdNetworkExtras> extras;

/// The value of childDirectedTreatment supplied by the publisher. Is nil if the publisher hasn't
/// specified child directed treatment. Is @YES if child directed treatment is enabled.
@property(nonatomic, nullable) NSNumber *childDirectedTreatment;

/// Indicates whether the publisher is requesting test ads.
@property(nonatomic) BOOL isTestRequest;

@end

/// Testable version of GADMediationBannerAdConfiguration. It overrides properties with readonly
/// attribute with readwrite attribute.
@interface AUTKMediationBannerAdConfiguration : GADMediationBannerAdConfiguration

/// The ad string returned from the 3PAS.
@property(nonatomic, nullable) NSString *bidResponse;

/// View controller to present from. This value must be read at presentation time to obtain the most
/// recent value. Must be accessed on the main queue.
@property(nonatomic, nullable) UIViewController *topViewController;

/// Mediation configuration set by the publisher on the AdMob frontend.
@property(nonatomic, nonnull) GADMediationCredentials *credentials;

/// PNG data containing a watermark that identifies the ad's source.
@property(nonatomic, nullable) NSData *watermark;

/// Extras the publisher registered with -[GADRequest registerAdNetworkExtras:].
@property(nonatomic, nullable) id<GADAdNetworkExtras> extras;

/// The value of childDirectedTreatment supplied by the publisher. Is nil if the publisher hasn't
/// specified child directed treatment. Is @YES if child directed treatment is enabled.
@property(nonatomic, nullable) NSNumber *childDirectedTreatment;

/// Indicates whether the publisher is requesting test ads.
@property(nonatomic) BOOL isTestRequest;

/// Banner ad size requested of the adapter.
@property(nonatomic) GADAdSize adSize;

@end

/// Testable version of GADMediationInterstitialAdConfiguration. It overrides properties with
/// readonly attribute with readwrite attribute.
@interface AUTKMediationInterstitialAdConfiguration : GADMediationInterstitialAdConfiguration

/// The ad string returned from the 3PAS.
@property(nonatomic, nullable) NSString *bidResponse;

/// View controller to present from. This value must be read at presentation time to obtain the most
/// recent value. Must be accessed on the main queue.
@property(nonatomic, nullable) UIViewController *topViewController;

/// Mediation configuration set by the publisher on the AdMob frontend.
@property(nonatomic, nonnull) GADMediationCredentials *credentials;

/// PNG data containing a watermark that identifies the ad's source.
@property(nonatomic, nullable) NSData *watermark;

/// Extras the publisher registered with -[GADRequest registerAdNetworkExtras:].
@property(nonatomic, nullable) id<GADAdNetworkExtras> extras;

/// The value of childDirectedTreatment supplied by the publisher. Is nil if the publisher hasn't
/// specified child directed treatment. Is @YES if child directed treatment is enabled.
@property(nonatomic, nullable) NSNumber *childDirectedTreatment;

/// Indicates whether the publisher is requesting test ads.
@property(nonatomic) BOOL isTestRequest;

@end

/// Testable version of GADMediationRewardedAdConfiguration. It overrides properties with readonly
/// attribute with readwrite attribute.
@interface AUTKMediationRewardedAdConfiguration : GADMediationRewardedAdConfiguration

/// The ad string returned from the 3PAS.
@property(nonatomic, nullable) NSString *bidResponse;

/// View controller to present from. This value must be read at presentation time to obtain the most
/// recent value. Must be accessed on the main queue.
@property(nonatomic, nullable) UIViewController *topViewController;

/// Mediation configuration set by the publisher on the AdMob frontend.
@property(nonatomic, nonnull) GADMediationCredentials *credentials;

/// PNG data containing a watermark that identifies the ad's source.
@property(nonatomic, nullable) NSData *watermark;

/// Extras the publisher registered with -[GADRequest registerAdNetworkExtras:].
@property(nonatomic, nullable) id<GADAdNetworkExtras> extras;

/// The value of childDirectedTreatment supplied by the publisher. Is nil if the publisher hasn't
/// specified child directed treatment. Is @YES if child directed treatment is enabled.
@property(nonatomic, nullable) NSNumber *childDirectedTreatment;

/// Indicates whether the publisher is requesting test ads.
@property(nonatomic) BOOL isTestRequest;

@end

/// Testable version of GADMediationNativeAdConfiguration. It overrides properties with readonly
/// attribute with readwrite attribute.
@interface AUTKMediationNativeAdConfiguration : GADMediationNativeAdConfiguration

/// The ad string returned from the 3PAS.
@property(nonatomic, nullable) NSString *bidResponse;

/// View controller to present from. This value must be read at presentation time to obtain the most
/// recent value. Must be accessed on the main queue.
@property(nonatomic, nullable) UIViewController *topViewController;

/// Mediation configuration set by the publisher on the AdMob frontend.
@property(nonatomic, nonnull) GADMediationCredentials *credentials;

/// PNG data containing a watermark that identifies the ad's source.
@property(nonatomic, nullable) NSData *watermark;

/// Extras the publisher registered with -[GADRequest registerAdNetworkExtras:].
@property(nonatomic, nullable) id<GADAdNetworkExtras> extras;

/// The value of childDirectedTreatment supplied by the publisher. Is nil if the publisher hasn't
/// specified child directed treatment. Is @YES if child directed treatment is enabled.
@property(nonatomic, nullable) NSNumber *childDirectedTreatment;

/// Indicates whether the publisher is requesting test ads.
@property(nonatomic) BOOL isTestRequest;

/// Additional options configured by the publisher for requesting a native ad.
@property(nonatomic, nonnull) NSArray<GADAdLoaderOptions *> *options;

@end

/// Testable version of GADRTBRequestParameters. It overrides properties with readonly
/// attribute with readwrite attribute.
@interface AUTKRTBRequestParameters : GADRTBRequestParameters

/// Mediation configuration for this request set by the publisher on the AdMob UI.
@property(nonatomic, nonnull) GADRTBMediationSignalsConfiguration *configuration;

/// Extras the publisher registered with -[GADRequest registerAdNetworkExtras:].
@property(nonatomic, nullable) id<GADAdNetworkExtras> extras;

/// Requested banner ad size. The ad size is GADAdSizeInvalid for non-banner requests.
@property(nonatomic) GADAdSize adSize;

@end

/// Testable version of GADRTBMediationSignalsConfiguration. It overrides properties with readonly
/// attribute with readwrite attribute.
@interface AUTKRTBMediationSignalsConfiguration : GADRTBMediationSignalsConfiguration

/// Array of mediation credential configurations set by the publisher on the AdMob UI. Each
/// credential configuration is a possible source of ads for the request. The real-time bidding
/// request will include a subset of these configurations.
@property(nonatomic, nonnull) NSArray<GADMediationCredentials *> *credentials;

@end
