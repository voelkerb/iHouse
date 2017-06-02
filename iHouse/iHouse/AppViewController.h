//
//  AppViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 08/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VoiceCommandViewController.h"
#import "MainAppViewController.h"
#import "PreferenceWindowController.h"

@interface AppViewController : NSObject <VoiceCommandViewControllerDelegate, MainAppViewControllerDelegate, PreferenceWindowControllerDelegate>

@property (weak) IBOutlet NSView *currentView;
@property (weak) IBOutlet NSWindow *appWindow;

// The controller for the SinusView
@property (strong) VoiceCommandViewController *voiceCommandViewController;
// The controller for the main application
@property (strong) MainAppViewController *mainAppViewController;
// The conrtoller object for the preference window
@property (strong) PreferenceWindowController *preferenceWindowController;

@end
