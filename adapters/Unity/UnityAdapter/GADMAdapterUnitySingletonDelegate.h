//
//  GADMAdapterUnitySingletonDelegate.h
//  AdMob-TestApp-Local
//
//  Created by Jindou Jiao on 01/30/2020.
//  Copyright © 2020 Unity Ads. All rights reserved.
//

#ifndef GADMAdapterUnitySingletonDelegate_h
#define GADMAdapterUnitySingletonDelegate_h


#endif /* GADMAdapterUnitySingletonDelegate_h */

@class GADMAdapterUnitySingleton;

@protocol GADMAdapterUnitySingletonDelegate <NSObject>

-(void)adapterUnityDidInitialize;

-(void)adapterUnityInitializedFailed:(NSError *) error;

@end
