//
//  AppDelegate.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 23/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "AppDelegate.h"
#import "NetworkController.h"
#import "SyncManager.h"
#import "House.h"
#import "Settings.h"
#import "WatchConnector.h"
#import "HouseSyncer.h"

#define DEBUG_APP_DELEGATE 1
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Override point for customization after application launch.
  if (DEBUG_APP_DELEGATE) NSLog(@"AppDidFinishLaunching");
  
  // Init watchconnector
  [WatchConnector sharedWatchConnector];
  [SyncManager sharedSyncManager];
  
  self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
  
  UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
  UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"connectionStoryboard"];
  
  // If house could be loaded from a file, then display rooms directly
  if ([[[House sharedHouse] roomList] count] > 0) {
    if (DEBUG_APP_DELEGATE) NSLog(@"House has some rooms");
    viewController = [storyboard instantiateViewControllerWithIdentifier:@"roomStoryboard"];
  // Display connection screen
  } else {
    if (DEBUG_APP_DELEGATE) NSLog(@"House does not have any room");
    viewController = [storyboard instantiateViewControllerWithIdentifier:@"connectionStoryboard"];
  }
  self.window.rootViewController = viewController;
  [self.window makeKeyAndVisible];
  
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  if (DEBUG_APP_DELEGATE) NSLog(@"applicationWillResignActive");
  [[SyncManager sharedSyncManager] disableAlertSheets];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  if (DEBUG_APP_DELEGATE) NSLog(@"applicationDidEnterBackground");
  //[[SyncManager sharedSyncManager] disconnectFromServer];
  [[SyncManager sharedSyncManager] disableAlertSheets];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  if (DEBUG_APP_DELEGATE) NSLog(@"applicationWillEnterForeground");
  [[SyncManager sharedSyncManager] connectToServer];
  [self performSelector:@selector(enableAlertSheetsAfterSomeTime) withObject:nil afterDelay:4];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  if (DEBUG_APP_DELEGATE) NSLog(@"applicationDidBecomeActive");
  [[SyncManager sharedSyncManager] connectToServer];
  [self performSelector:@selector(enableAlertSheetsAfterSomeTime) withObject:nil afterDelay:4];
}

// Enable alert sheets not directly but after some time to see if connection to server could be established
- (void)enableAlertSheetsAfterSomeTime {
  [[SyncManager sharedSyncManager] enableAlertSheets];
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  if (DEBUG_APP_DELEGATE) NSLog(@"applicationWillTerminate");
}

@end
