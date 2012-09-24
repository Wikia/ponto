//
//  PontoDEMOAppDelegate.h
//  Ponto
//
//  Created by Gregor <grzegorz@wikia-inc.com> on 09/21/12.
//  Copyright (c) 2012 Wikia Sp. z o.o. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface PontoDEMOAppDelegate : UIResponder <UIApplicationDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UINavigationController *navigationController;

- (void)displaySendEmailMessagePickerWithRecipients:(NSArray *)recipients andSubject:(NSString *)subject andBody:(NSString *)body;

@end