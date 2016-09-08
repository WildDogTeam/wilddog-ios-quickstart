//
//  Utils.h
//  AuthenticationExample
//
//  Created by Garin on 16/8/30.
//  Copyright © 2016年 www.wilddog.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WDGAuth;
/**
 *  Wilddog appID
 */
static NSString *const kWilddogAppID = @"unittest";

@interface Utils : NSObject

+ (WDGAuth *)auth;

@end
