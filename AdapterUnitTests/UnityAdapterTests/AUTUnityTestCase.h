#import <XCTest/XCTest.h>

#import "GADMediationAdapterUnity.h"

/// Game ID to be used for initializing UnityAds.
static NSString *_Nonnull AUTUnityGameID = @"123";

/// Placement ID to be used for loading Unity ads,
static NSString *_Nonnull AUTUnityPlacementID = @"456";

/// Test bidresponse.
static NSString *_Nonnull AUTUnityBidResponse = @"bidresponse";

static NSString *_Nonnull AUTUnityWatermarkBase64 =
    @"iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAADTUlEQVR42u2cC2sTQRSFE6qoaKGo+MAUk+"
    @"ymtex2d5NIfaRoUFG0tEVD/P//"
    @"5DhnbaDWtklKHntnzgfzA3bO7Jx779yZWk0IIYQQQgghhBBCCCG8ZoyNLMP9KMOTKMV21EMc50jiFFGzQLOZ4FmS4IEma"
    @"kk03uHeboZWO8dhlOOnm/zfM40C43aGz60UGUWikJrNG8IV3ulhjxM6swBTBsVsd/F6p4/HmuE5/"
    @"oZWjgOu7kUJcdnY6eJLnKGhGb+"
    @"C5hB3OwWKTobRMoW4TJhXB3gkBc5BU57LG5YwuJUNh7gVfLRUbk9rFOIfUQr8aCR4GKxXlPt4RcSYjHLLDM1bGOW4jz6p"
    @"mhgX/pZOGOZdYMvlE7+qLEYwojCSqvqfcXEwIfVSDEYwVfSMWbJ9DxNJ1KMCA3NiTEaG4zjGHW/"
    @"kYNHPrBiTsotbUF6I0e/jtjXfuDKrz/"
    @"HCfhaeIfVBjLOo68h0xZhnFquuTSkUvgYnxhufxJiUVxik2DNyF5Usu4S+"
    @"xqjLXmml1cVLL8XgX5Lj0J6ZW847ZkgWTeUlzMp9M/P/"
    @"8pIU23b8w+2xPotRCrKPviVBegEI8t2Sf7z3XRD6iJnwd5GtO5UuzQ+"
    @"waUOQAkchCMLOSRseEoAYpoqNoQjCPmIJohLKjYqKoxAEMdPxGIqp83jBxpZVYBiCIJYy9bcB+"
    @"MexndJ7isx3QZj8WhLkaQBJYWroNAR15yOnnucgW6YOqHjfwtvtqjxXN8ZeH8+9LZl0kdtrORljw0qX+"
    @"9yCWO319alJ7pyZfzLbl+VTG+lkmL/"
    @"yxvsVvojBxr+"
    @"afVwInOObB2KMzNSupsFnLawLwupDzSfKx2GsCtLFR5P9vDOck5hrvma7j78PCrjchGGjoYruiffPPPEmLksPFkw8mFeD"
    @"SlGq3Lvl/"
    @"owAH6RBvYoFSC4ULphaqJSJY0Uu9nCBeBlNzQu3BzchX9e5RZnpsVol7ARcpeHzja5Whl29xTjFW7hal9lKdHYskLD4qf"
    @"meQxiezfPZv4X8NQVOmZjy5pNejluE+Q+wyVdKO/v4UPrNNWV9bkXMsNkfxtO9v/"
    @"mEzHolsALLMwpOelmNlR8IIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGE3/wBjW9SKC7yayAAAAAASUVORK5CYII=";

/// Subclass of XCTestCase to faciliate GADMediationAdapterUnity tests.
@interface AUTUnityTestCase : XCTestCase

/// Class mocked UnityAds.
@property(nonatomic, nonnull) id unityAdsClassMock;

/// Unity adapter that is being tested.
@property(nonatomic, nonnull) GADMediationAdapterUnity *adapter;

@end
