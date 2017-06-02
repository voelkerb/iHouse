//
//  AppViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 08/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "AppViewController.h"

#define DEBUG 1


@implementation AppViewController
@synthesize currentView, voiceCommandViewController, mainAppViewController, preferenceWindowController, appWindow;

-(void)awakeFromNib {
  // Init the view controllers and set their delegates
  mainAppViewController = [[MainAppViewController alloc] initWithNibName:@"MainAppView" bundle:nil];
  [mainAppViewController setDelegate:self];
  
  // Add the two viewController to the current view and set the bounds of the view to this frame
  // and as resizeable in width and height
  // By default the voice view is hidden
  [voiceCommandViewController view].hidden = NO;
  [currentView addSubview:[voiceCommandViewController view]];
  [[voiceCommandViewController view] setFrame:[currentView bounds]];
  [[voiceCommandViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  
  [currentView addSubview:[mainAppViewController view]];
  [[mainAppViewController view] setFrame:[currentView bounds]];
  [[mainAppViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  
  // Add observer to get notified if voice command view should be enabled
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startVoiceCommand:) name:StartVoiceCommandDetection object:nil];
  
}

# pragma Delegate Call from voiceCommandViewController to close the dictation window again
- (void)closeVoiceCommandWindow {
  // Remove voice commandview
  [[voiceCommandViewController view] removeFromSuperview];
  // Add mainview back
  [currentView addSubview:[mainAppViewController view]];
  [[mainAppViewController view] setFrame:[currentView bounds]];
  [[mainAppViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
}

# pragma Delegate Call from mainAppViewController to open the preference window
- (void)openPreferenceWindow {
  [self openPreferenceWindow:self];
}

/**
 * Open the Preference Window
 */
- (IBAction)openPreferenceWindow:(id)sender {
  // If the window is not open its controller is nil.
  if (preferenceWindowController == nil) {
    // Init the controller
    preferenceWindowController = [[PreferenceWindowController alloc] initWithWindowNibName:@"PreferenceWindow"];
  }
  // Make it to frontmost window
  [[preferenceWindowController window] makeKeyAndOrderFront:self];
}

/**
 * Delegate methode if preferences did close
 */
-(void)preferencesDidClose {
  if (DEBUG) NSLog(@"Preferences did close");
}


/*
 * Changes view to voice view, called from micro notification.
 */
-(void)startVoiceCommand:(NSNotification*)notification {
  if (DEBUG) NSLog(@"Starting voice command detection");
  // Search for the room the micro is stored in
  for (Room *theRoom in [[House sharedHouse] rooms]) {
    for (IDevice *theDevice in [theRoom devices]) {
      if ([[notification object] isEqualTo:theDevice.theDevice]) {
        if (DEBUG) NSLog(@"Start voice in Room: %@", theRoom);
        Settings *setting = [Settings sharedSettings];
        if (![setting enableVoice]) return;
        // Remove mainview from superview
        [[mainAppViewController view] removeFromSuperview];
        if (!voiceCommandViewController) {
          voiceCommandViewController = [[VoiceCommandViewController alloc] init];
          [voiceCommandViewController setDelegate:self];
        }
        // Add dictation window on top of other views and set the bounds of it to be sizeable
        [currentView addSubview:[voiceCommandViewController view]];
        [[voiceCommandViewController view] setFrame:[currentView bounds]];
        [[voiceCommandViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [voiceCommandViewController startListeningInRoom:theRoom];
        return;
      }
    }
  }
  
  Settings *setting = [Settings sharedSettings];
  if (![setting enableVoice]) return;
  // Remove mainview from superview
  [[mainAppViewController view] removeFromSuperview];
  if (!voiceCommandViewController) {
    voiceCommandViewController = [[VoiceCommandViewController alloc] init];
    [voiceCommandViewController setDelegate:self];
  }
  // Add dictation window on top of other views and set the bounds of it to be sizeable
  [currentView addSubview:[voiceCommandViewController view]];
  [[voiceCommandViewController view] setFrame:[currentView bounds]];
  [[voiceCommandViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [voiceCommandViewController startListening];
}

/*
 * Changes view to voice view, called from menu.
 */
- (IBAction)changeView:(id)sender {
  Settings *setting = [Settings sharedSettings];
  if (![setting enableVoice]) return;
  // Remove mainview from superview
  [[mainAppViewController view] removeFromSuperview];
  if (!voiceCommandViewController) {
    voiceCommandViewController = [[VoiceCommandViewController alloc] init];
    [voiceCommandViewController setDelegate:self];
  }
  // Add dictation window on top of other views and set the bounds of it to be sizeable
  [currentView addSubview:[voiceCommandViewController view]];
  [[voiceCommandViewController view] setFrame:[currentView bounds]];
  [[voiceCommandViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [voiceCommandViewController startListening];
}

@end
