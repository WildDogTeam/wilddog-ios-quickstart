//
//  CustomTokenViewController.m
//  AuthenticationExample
//
//  Created by Garin on 16/8/29.
//  Copyright © 2016年 www.wilddog.com. All rights reserved.
//

#import "CustomTokenViewController.h"
#import "UIViewController+Alerts.h"
#import "Utils.h"

// [START auth_view_import]
@import WilddogAuth;
// [END auth_view_import]

@interface CustomTokenViewController ()
@property(weak, nonatomic) IBOutlet UITextView *tokenField;
@end
@implementation CustomTokenViewController

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [self.view endEditing:YES];
}

- (IBAction)didTapCustomTokenLogin:(id)sender {
  NSString *customToken = _tokenField.text;
  [self showSpinner:^{
    // [START signinwithcustomtoken]
    [[Utils auth] signInWithCustomToken:customToken
                               completion:^(WDGUser *_Nullable user,
                                            NSError *_Nullable error) {
                                 // [START_EXCLUDE]
                                 [self hideSpinner:^{
                                   if (error) {
                                     [self showMessagePrompt:error.localizedDescription];
                                     return;
                                   }
                                   [self.navigationController popViewControllerAnimated:YES];
                                 }];
                                 // [END_EXCLUDE]
                               }];
    // [END signinwithcustomtoken]
  }];
}

@end
