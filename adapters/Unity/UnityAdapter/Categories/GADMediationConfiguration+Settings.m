//
//  GADMediationAdConfiguration+Settings.m
//  AdMob-TestApp-Local
//
//  Created by Vita Solomina on 2021-10-18.
//  Copyright © 2021 Unity Ads. All rights reserved.
//

#import "GADMediationConfiguration+Settings.h"
#import "GADMAdapterUnityConstants.h"

@implementation GADMediationAdConfiguration (Settings)

- (NSString *)placementId {
    return self.credentials.settings[kGADMAdapterUnityPlacementID];
}

- (NSString *)gameId {
    return self.credentials.settings[kGADMAdapterUnityGameID];
}

@end

@implementation GADMediationServerConfiguration (Settings)

- (NSSet*)gameIds {
    NSMutableSet *gameIDs = [[NSMutableSet alloc] init];
    for (GADMediationCredentials *cred in self.credentials) {
        NSString *gameIDFromSettings = cred.settings[kGADMAdapterUnityGameID];
        [gameIDs addObject: gameIDFromSettings];
    }
    return gameIDs;
}

@end
