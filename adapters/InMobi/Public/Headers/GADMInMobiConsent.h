//
//  GADMInMobiConsent.h
//  Adapter
//
//  Created by Ankit Pandey on 24/05/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GADMInMobiConsent : NSObject
/**
 * Updates GDPR consent for InMobi AdRequest
 */
+(void)updateGDPRConsent:(NSDictionary*) consent;
/**
 * fetches GDPR consent for InMobi AdRequest
 */
+(NSMutableDictionary*) getConsent;

@end
