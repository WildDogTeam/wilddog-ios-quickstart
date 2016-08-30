//
//  MainViewController.m
//  AuthenticationExample
//
//  Created by Garin on 16/8/29.
//  Copyright © 2016年 www.wilddog.com. All rights reserved.
//

#import "MainViewController.h"
#import "UIViewController+Alerts.h"
#import "Utils.h"

#import <TencentOpenAPI/TencentOAuth.h>
#import "WXApi.h"

@import Wilddog;
@import WilddogAuth;

static const int kSectionToken = 3;
static const int kSectionProviders = 2;
static const int kSectionUser = 1;
static const int kSectionSignIn = 0;

typedef enum : NSUInteger {
    AuthEmail,
    AuthAnonymous,
    AuthQQ,
    AuthWeixin,
    AuthSina,
    AuthCustom
} AuthProvider;

/*! @var kOKButtonText
 @brief The text of the "OK" button for the Sign In result dialogs.
 */
static NSString *const kOKButtonText = @"OK";

/*! @var kTokenRefreshedAlertTitle
 @brief The title of the "Token Refreshed" alert.
 */
static NSString *const kTokenRefreshedAlertTitle = @"Token";

/*! @var kTokenRefreshErrorAlertTitle
 @brief The title of the "Token Refresh error" alert.
 */
static NSString *const kTokenRefreshErrorAlertTitle = @"Get Token Error";

/** @var kSetDisplayNameTitle
 @brief The title of the "Set Display Name" error dialog.
 */
static NSString *const kSetDisplayNameTitle = @"Set Display Name";

/** @var kUnlinkTitle
 @brief The text of the "Unlink from Provider" error Dialog.
 */
static NSString *const kUnlinkTitle = @"Unlink from Provider";

/** @var kChangeEmailText
 @brief The title of the "Change Email" button.
 */
static NSString *const kChangeEmailText = @"Change Email";

/** @var kChangePasswordText
 @brief The title of the "Change Password" button.
 */
static NSString *const kChangePasswordText = @"Change Password";


@interface MainViewController ()
{
    TencentOAuth *_tencentOAuth;
    NSArray *_permissions;
}
@property(strong, nonatomic) WDGAuthStateDidChangeListenerHandle handle;
@end

@implementation MainViewController

- (void)wilddogLoginWithCredential:(id)object {
    
    WDGAuthCredential *credential ;
    NSDictionary *userInfo = ((NSNotification *)object).userInfo;
    
    if ([credential isKindOfClass:[NSNotification class]]) {
        credential = [userInfo objectForKey:@"credential"];
    }else{
        credential = object;
    }
    
    [self showSpinner:^{
        if ([Utils auth].currentUser) {
            // [START link_credential]
            [[Utils auth]
             .currentUser linkWithCredential:credential
             completion:^(WDGUser *_Nullable user, NSError *_Nullable error) {
                 // [START_EXCLUDE]
                 [self hideSpinner:^{
                     if (error) {
                         [self showMessagePrompt:error.localizedDescription];
                         return;
                     }
                     [self.tableView reloadData];
                 }];
                 // [END_EXCLUDE]
             }];
            // [END link_credential]
        } else {
            // [START signin_credential]
            [[Utils auth] signInWithCredential:credential
                                      completion:^(WDGUser *user, NSError *error) {
                                          // [START_EXCLUDE]
                                          [self hideSpinner:^{
                                              if (error) {
                                                  [self showMessagePrompt:error.localizedDescription];
                                                  return;
                                              }
                                          }];
                                          // [END_EXCLUDE]
                                      }];
            // [END signin_credential]
        }
    }];
}

- (void)showAuthPicker: (NSArray<NSNumber *>*) providers {
    UIAlertController *picker = [UIAlertController alertControllerWithTitle:@"Select Provider"
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (NSNumber *provider in providers) {
        UIAlertAction *action;
        switch (provider.unsignedIntegerValue) {
            case AuthEmail:
            {
                action = [UIAlertAction actionWithTitle:@"Email" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self performSegueWithIdentifier:@"email" sender:nil];
                }];
            }
                break;
            case AuthCustom:
            {
                action = [UIAlertAction actionWithTitle:@"Custom" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self performSegueWithIdentifier:@"customToken" sender:nil];
                }];
            }
                break;
            case AuthQQ:
            {
                action = [UIAlertAction actionWithTitle:@"QQ" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    
                    _tencentOAuth = [[TencentOAuth alloc] initWithAppId:@"222222" andDelegate:self];
                     _permissions =  [NSArray arrayWithObjects:@"get_user_info", @"get_simple_userinfo", @"add_t", nil];
                    [_tencentOAuth authorize: _permissions inSafari:NO];
                }];
            }
                break;
            case AuthWeixin: {
                action = [UIAlertAction actionWithTitle:@"Weixin" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    
                    SendAuthReq *req = [SendAuthReq new];
                    req.scope = @"snsapi_userinfo" ;
                    req.state = @"osc_wechat_login" ;
                    //第三方向微信终端发送一个SendAuthReq消息结构
                    [WXApi sendReq:req];
                }];
            }
                break;
            case AuthSina: {
                action = [UIAlertAction actionWithTitle:@"Sina" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    
                }];
            }
                break;
            case AuthAnonymous: {
                action = [UIAlertAction actionWithTitle:@"Anonymous" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self showSpinner:^{
                        // [START wilddog_auth_anonymous]
                        [[Utils auth]
                         signInAnonymouslyWithCompletion:^(WDGUser *_Nullable user, NSError *_Nullable error) {
                             // [START_EXCLUDE]
                             [self hideSpinner:^{
                                 if (error) {
                                     [self showMessagePrompt:error.localizedDescription];
                                     return;
                                 }
                             }];
                             // [END_EXCLUDE]
                         }];
                        // [END wilddog_auth_anonymous]
                    }];
                }];
            }
                break;
        }
        [picker addAction:action];
    }
    
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [picker addAction:cancel];
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)tencentDidLogin
{
    if (_tencentOAuth.accessToken && 0 != [_tencentOAuth.accessToken length])
    {
        // [START headless_twitter_auth]
        WDGAuthCredential *credential = [WDGQQAuthProvider credentialWithAccessToken:_tencentOAuth.accessToken];
        
        // [END headless_twitter_auth]
        [self wilddogLoginWithCredential:credential];
    }
}

//非网络错误导致登录失败：
-(void)tencentDidNotLogin:(BOOL)cancelled
{
    [self showMessagePrompt:@"登录失败"];
}

//网络错误导致登录失败：
-(void)tencentDidNotNetWork
{
    [self showMessagePrompt:@"登录失败"];
}

- (IBAction)didTapSignIn:(id)sender {
    [self showAuthPicker:@[@(AuthEmail),
                           @(AuthAnonymous),
                           @(AuthQQ),
                           @(AuthWeixin),
                           @(AuthSina),
                           @(AuthCustom)]];
}

- (IBAction)didTapLink:(id)sender {
    NSMutableArray *providers = [@[@(AuthQQ),
                                   @(AuthWeixin),
                                   @(AuthSina)] mutableCopy];
    
    // Remove any existing providers. Note that this is not a complete list of
    // providers, so always check the documentation for a complete reference:

    for (id<WDGUserInfo> userInfo in [Utils auth].currentUser.providerData) {
        if ([userInfo.providerID isEqualToString:WDGQQAuthProviderID]) {
            [providers removeObject:@(AuthQQ)];
        } else if ([userInfo.providerID isEqualToString:WDGWeiXinAuthProviderID]) {
            [providers removeObject:@(AuthWeixin)];
        } else if ([userInfo.providerID isEqualToString:WDGSinaAuthProviderID]) {
            [providers removeObject:@(AuthSina)];
        }
    }
    [self showAuthPicker:providers];
}

- (IBAction)didTapSignOut:(id)sender {
    // [START signout]
    NSError *signOutError;
    BOOL status = [[Utils auth] signOut:&signOutError];
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
    // [END signout]
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.handle = [[Utils auth]
                   addAuthStateDidChangeListener:^(WDGAuth *_Nonnull auth, WDGUser *_Nullable user) {
                       [self setTitleDisplay:user];
                       [self.tableView reloadData];
                   }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wilddogLoginWithCredential:) name:@"WeixinSignIn" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wilddogLoginWithCredential:) name:@"WeiboSignIn" object:nil];
}

- (void)setTitleDisplay: (WDGUser *)user {
    if (user.displayName) {
        self.navigationItem.title = [NSString stringWithFormat:@"Welcome %@", user.displayName];
    } else {
        self.navigationItem.title = @"Authentication Example";
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[Utils auth] removeAuthStateDidChangeListener:_handle];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kSectionSignIn) {
        return 1;
    } else if (section == kSectionUser || section == kSectionToken) {
        if ([Utils auth].currentUser) {
            return 1;
        } else {
            return 0;
        }
    } else if (section == kSectionProviders) {
        return [[Utils auth].currentUser.providerData count];
    }
    NSAssert(NO, @"Unexpected section");
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.section == kSectionSignIn) {
        if ([Utils auth].currentUser) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"SignOut"];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"SignIn"];
        }
    } else if (indexPath.section == kSectionUser) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Profile"];
        WDGUser *user = [Utils auth].currentUser;
        UILabel *emailLabel = [(UILabel *)cell viewWithTag:1];
        UILabel *userIDLabel = [(UILabel *)cell viewWithTag:2];
        UIImageView *profileImageView = [(UIImageView *)cell viewWithTag:3];
        emailLabel.text = user.email;
        userIDLabel.text = user.uid;
        
        NSURL *photoURL = user.photoURL;
        static NSURL *lastPhotoURL = nil;
        lastPhotoURL = photoURL;  // to prevent earlier image overwrites later one.
        if (photoURL) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:photoURL]];
                dispatch_async(dispatch_get_main_queue(), ^() {
                    if (photoURL == lastPhotoURL) {
                        profileImageView.image = image;
                    }
                });
            });
        } else {
            profileImageView.image = [UIImage imageNamed:@"ic_account_circle"];
        }
    } else if (indexPath.section == kSectionProviders) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Provider"];
        id<WDGUserInfo> userInfo = [Utils auth].currentUser.providerData[indexPath.row];
        cell.textLabel.text = [userInfo providerID];
        cell.detailTextLabel.text = [userInfo uid];
    } else if (indexPath.section == kSectionToken) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Token"];
        UIButton *requestEmailButton = [(UIButton *)cell viewWithTag:4];
        requestEmailButton.enabled = [Utils auth].currentUser.email ? YES : NO;
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView
titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Unlink";
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionProviders) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

// Swipe to delete.
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *providerID = [[Utils auth].currentUser.providerData[indexPath.row] providerID];
        [self showSpinner:^{
            // [START unlink_provider]
            [[Utils auth]
             .currentUser unlinkFromProvider:providerID
             completion:^(WDGUser *_Nullable user, NSError *_Nullable error) {
                 // [START_EXCLUDE]
                 [self hideSpinner:^{
                     if (error) {
                         [self showMessagePrompt:error.localizedDescription];
                         return;
                     }
                     [self.tableView reloadData];
                 }];
                 // [END_EXCLUDE]
             }];
            // [END unlink_provider]
        }];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kSectionUser) {
        return 200;
    }
    return 44;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (IBAction)didTokenRefresh:(id)sender {
    WDGAuthTokenCallback action = ^(NSString *_Nullable token, NSError *_Nullable error) {
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:kOKButtonText
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             NSLog(kOKButtonText);
                                                         }];
        if (error) {
            UIAlertController *alertController =
            [UIAlertController alertControllerWithTitle:kTokenRefreshErrorAlertTitle
                                                message:error.localizedDescription
                                         preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
            return;
        }
        
        
        UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:kTokenRefreshedAlertTitle
                                            message:token
                                     preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    };
    // [START token_refresh]
    [[Utils auth].currentUser getTokenWithCompletion:action];
    // [END token_refresh]
}


/** @fn setDisplayName
 @brief Changes the display name of the current user.
 */
- (IBAction)didSetDisplayName:(id)sender {
    [self showTextInputPromptWithMessage:@"Display Name:"
                         completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
                             if (!userPressedOK || !userInput.length) {
                                 return;
                             }
                             
                             [self showSpinner:^{
                                 // [START profile_change]
                                 WDGUserProfileChangeRequest *changeRequest =
                                 [[Utils auth].currentUser profileChangeRequest];
                                 changeRequest.displayName = userInput;
                                 [changeRequest commitChangesWithCompletion:^(NSError *_Nullable error) {
                                     // [START_EXCLUDE]
                                     [self hideSpinner:^{
                                         [self showTypicalUIForUserUpdateResultsWithTitle:kSetDisplayNameTitle
                                                                                    error:error];
                                         [self setTitleDisplay:[Utils auth].currentUser];
                                     }];
                                     // [END_EXCLUDE]
                                 }];
                                 // [END profile_change]
                             }];
                         }];
}

/** @fn requestVerifyEmail
 @brief Requests a "verify email" email be sent.
 */
- (IBAction)didRequestVerifyEmail:(id)sender {
    [self showSpinner:^{
        // [START send_verification_email]
        [[Utils auth]
         .currentUser sendEmailVerificationWithCompletion:^(NSError *_Nullable error) {
             // [START_EXCLUDE]
             [self hideSpinner:^{
                 if (error) {
                     [self showMessagePrompt:error.localizedDescription];
                     return;
                 }
                 
                 [self showMessagePrompt:@"Sent"];
             }];
             // [END_EXCLUDE]
         }];
        // [END send_verification_email]
    }];
}

/** @fn changeEmail
 @brief Changes the email address of the current user.
 */
- (IBAction)didChangeEmail:(id)sender {
    [self showTextInputPromptWithMessage:@"Email Address:"
                         completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
                             if (!userPressedOK || !userInput.length) {
                                 return;
                             }
                             
                             [self showSpinner:^{
                                 // [START change_email]
                                 [[Utils auth]
                                  .currentUser
                                  updateEmail:userInput
                                  completion:^(NSError *_Nullable error) {
                                      // [START_EXCLUDE]
                                      [self hideSpinner:^{
                                          [self
                                           showTypicalUIForUserUpdateResultsWithTitle:kChangeEmailText
                                           error:error];
                                          
                                      }];
                                      // [END_EXCLUDE]
                                  }];
                                 // [END change_email]
                             }];
                         }];
}

/** @fn changePassword
 @brief Changes the password of the current user.
 */
- (IBAction)didChangePassword:(id)sender {
    [self showTextInputPromptWithMessage:@"New Password:"
                         completionBlock:^(BOOL userPressedOK, NSString *_Nullable userInput) {
                             if (!userPressedOK || !userInput.length) {
                                 return;
                             }
                             
                             [self showSpinner:^{
                                 // [START change_password]
                                 [[Utils auth]
                                  .currentUser
                                  updatePassword:userInput
                                  completion:^(NSError *_Nullable error) {
                                      // [START_EXCLUDE]
                                      [self hideSpinner:^{
                                          [self showTypicalUIForUserUpdateResultsWithTitle:
                                           kChangePasswordText
                                                                                     error:error];
                                      }];
                                      // [END_EXCLUDE]
                                  }];
                                 // [END change_password]
                             }];
                         }];
}

/** @fn showTypicalUIForUserUpdateResultsWithTitle:error:
 @brief Shows a @c UIAlertView if error is non-nil with the localized description of the error.
 @param resultsTitle The title of the @c UIAlertView
 @param error The error details to display if non-nil.
 */
- (void)showTypicalUIForUserUpdateResultsWithTitle:(NSString *)resultsTitle error:(NSError *)error {
    if (error) {
        NSString *message = [NSString stringWithFormat:@"%@ (%ld)\n%@", error.domain, (long)error.code,
                             error.localizedDescription];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:resultsTitle
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:kOKButtonText, nil];
        [alert show];
        return;
    }
    [self.tableView reloadData];
}

@end
