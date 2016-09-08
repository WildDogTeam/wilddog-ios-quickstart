//
//  AppDelegate.m
//  AuthenticationExample
//
//  Created by Garin on 16/8/29.
//  Copyright © 2016年 www.wilddog.com. All rights reserved.
//

#import "AppDelegate.h"
@import WilddogAuth;
@import WilddogSync;
#import "Utils.h"

//引入第三方库
#import <TencentOpenAPI/TencentOAuth.h>
#import "WXApi.h"
#import "WeiboSDK.h"

#define WeiXin_KEY        @"wxca57c139d7ab1a5f"
#define WeiBo_KEY         @"57753611"

@interface AppDelegate () <WXApiDelegate,WeiboSDKDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //向微信注册
    [WXApi registerApp:WeiXin_KEY];
    
    //向微博注册
    [WeiboSDK registerApp:WeiBo_KEY];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    if ([url.absoluteString hasPrefix:@"wx"]) {
        return [WXApi handleOpenURL:url delegate:self];
    }else if ([url.absoluteString hasPrefix:@"wb"]) {
        return [WeiboSDK handleOpenURL:url delegate:self ];
    }else if ([url.absoluteString hasPrefix:@"tencent"]) {
        return [TencentOAuth HandleOpenURL:url];
    }
    return NO;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([url.absoluteString hasPrefix:@"wx"]) {
        return [WXApi handleOpenURL:url delegate:self];
    }else if ([url.absoluteString hasPrefix:@"wb"]) {
        return [WeiboSDK handleOpenURL:url delegate:self ];
    }else if ([url.absoluteString hasPrefix:@"tencent"]) {
        return [TencentOAuth HandleOpenURL:url];
    }
    return NO;
}

#pragma mark - WeiChatSDKDelegate
-(void) onReq:(BaseReq*)req
{
    
}
/*! @brief 发送一个sendReq后，收到微信的回应
 *
 * 收到一个来自微信的处理结果。调用一次sendReq后会收到onResp。
 * 可能收到的处理结果有SendMessageToWXResp、SendAuthResp等。
 * @param resp具体的回应内容，是自动释放的
 */
-(void) onResp:(BaseResp*)resp
{
    if([resp isKindOfClass:[SendAuthResp class]])
    {
        SendAuthResp *response = (SendAuthResp*)resp;
        if(response.code.length == 0){
            return;
        }
        WDGAuthCredential *credential = [WDGWeiXinAuthProvider credentialWithCode:response.code];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WeiXinSignIn" object:nil userInfo:@{@"credential":credential}];
    }
}

#pragma mark - WeiboSDKDelegate

- (void)didReceiveWeiboResponse:(WBBaseResponse *)response
{
    if ([response isKindOfClass:WBAuthorizeResponse.class])
    {
        WBAuthorizeResponse *wbResponse = (WBAuthorizeResponse *)response;
        if (wbResponse.accessToken == nil || wbResponse.userID == nil) {
            return;
        }
        WDGAuthCredential *credential = [WDGSinaAuthProvider credentialWithAccessToken:wbResponse.accessToken userID:wbResponse.userID];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WeiboSignIn" object:nil userInfo:@{@"credential":credential}];
    }
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
