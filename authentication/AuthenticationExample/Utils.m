//
//  Utils.m
//  AuthenticationExample
//
//  Created by Garin on 16/8/30.
//  Copyright © 2016年 www.wilddog.com. All rights reserved.
//

#import "Utils.h"

@import WilddogAuth;

@implementation Utils

+ (WDGAuth *)auth
{
    return [WDGAuth authWithAppID:kWilddogAppID];
}

@end
