#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADMediationAdConfiguration (AdapterUnitTests)
- (nonnull instancetype)initWithAdConfiguration:(nullable id)adConfiguration
                                      targeting:(nullable id)targeting
                                    credentials:(nonnull GADMediationCredentials *)credentials
                                         extras:(nullable id<GADAdNetworkExtras>)extras;
@end

@interface GADMediationBannerAdConfiguration (AdapterUnitTests)
- (nonnull instancetype)initWithAdSize:(GADAdSize)adSize
                       adConfiguration:(nullable id)adConfiguration
                             targeting:(nullable id)targeting
                           credentials:(nonnull GADMediationCredentials *)credentials
                                extras:(nullable id<GADAdNetworkExtras>)extras;
@end

@interface GADMediationNativeAdConfiguration (AdapterUnitTests)
- (nonnull instancetype)initWithOptions:(nullable NSArray<GADAdLoaderOptions *> *)options
                        adConfiguration:(nullable id)adConfiguration
                              targeting:(nullable id)targeting
                            credentials:(nonnull GADMediationCredentials *)credentials
                                 extras:(nullable id<GADAdNetworkExtras>)extras;
@end

@interface GADMediationCredentials (AdapterUnitTests)
- (nonnull instancetype)initWithAdFormat:(GADAdFormat)format
                             credentials:(nullable NSDictionary<NSString *, id> *)credentials;
@end
