//
//  PontoDEMOAppDelegate.m
//  Ponto
//
//  Created by Gregor <grzegorz@wikia-inc.com> on 09/21/12.
//  Copyright (c) 2012 Wikia Sp. z o.o. All rights reserved.
//

#import "PontoDEMOAppDelegate.h"
#import "PontoDEMOViewController.h"

@implementation PontoDEMOAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

    PontoDEMOViewController *pontoDEMOViewController = [[PontoDEMOViewController alloc] initWithNibName:@"PontoDEMOViewController" bundle:[NSBundle mainBundle]];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:pontoDEMOViewController];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

}

- (void)displaySendEmailMessagePickerWithRecipients:(NSArray *)recipients andSubject:(NSString *)subject andBody:(NSString *)body {
    MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
    mailComposeViewController.mailComposeDelegate = self;
    [mailComposeViewController setToRecipients:recipients];
    [mailComposeViewController setSubject:subject];
    [mailComposeViewController setMessageBody:body isHTML:YES];
    [self.navigationController presentModalViewController:mailComposeViewController animated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

@end