//
//  AppDelegate.m
//  iHouse
//
//  Created by Benjamin Völker on 06/07/15.
//  Copyright © 2015 Benjamin Völker.
//  eMail:      voelkerb@me.com.
//  Company:    University of Freiburg.
//  Education:  Master of Science, Embedded Systems Engineering.
//

#import "AppDelegate.h"
#import "AVBufferedPlayer.h"

#define DEBUG_APP_DELEGATE 0
#define FULLSCREEN_READY 1
#define FULLSCREEN_ON_START 0
#define FOLDER_NAME @"iHouse Data"
#define FILE_ENDING @".house"
#define FILE_NAME @"yourHouse"


@interface AppDelegate ()

// The window Object the Application runs in
@property (weak) IBOutlet NSWindow *appWindow;


@end

@implementation AppDelegate
@synthesize serialConnectionHandler, tcpServer, microphoneStreamHandler;

/**
 * Is called if the Application finished launching
 */
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // Load stored application data
  [self loadDataFromDisk];
  
  // Start tpc server and serial connection
  serialConnectionHandler = [SerialConnectionHandler sharedSerialConnectionHandler];
  microphoneStreamHandler = [MicrophoneStreamHandler sharedMicrophoneStreamHandler];
  tcpServer = [TCPServer sharedTCPServer];
  [tcpServer startServer];
  
  
  // Init USB Audio Player with default settings 11kHz, 1000 samples per block, 4 Bit PCM
  if (ENABLE_USB_AUDIO) {
    AVBufferedPlayer *buffPlayer = [AVBufferedPlayer sharedAVBufferedPlayer];
    // Start playback -> will give a pop sound
    [buffPlayer play];
  }
  
  // If the window is not fullscreen yet, toggle to fullscreen
  if (!([self.appWindow styleMask] & NSFullScreenWindowMask) & FULLSCREEN_READY) {
    // Make window Fullscreen but not tileable if System running at 10.11
    
    if (NSAppKitVersionNumber > NSAppKitVersionNumber10_10_3) {
      [self.appWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenDisallowsTiling
       | NSWindowCollectionBehaviorFullScreenPrimary];
    } else {
      [self.appWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    }
    
    // Toggle app to fullscreen
    if (FULLSCREEN_ON_START) [self.appWindow toggleFullScreen:self];
  }
  // Set the style of the appWindow
  self.appWindow.styleMask = self.appWindow.styleMask | NSFullSizeContentViewWindowMask;
  self.appWindow.titlebarAppearsTransparent = true;
  // Add an observer to get a notification if app enters foreground
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appEnteredForeground:)
                                               name:NSApplicationDidBecomeActiveNotification
                                             object:nil];
}


/**
 * Is called if the Application terminates
 */
- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Close serialConnection and stop tcp server
  [serialConnectionHandler closePort];
  [tcpServer stopServer];
  
  if (DEBUG_APP_DELEGATE) NSLog(@"Application is closing");
  // Remove foreground observer
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  // Store data to disk
  House *theHouse = [House sharedHouse];
  BOOL success = [theHouse store:self];
  if (DEBUG_APP_DELEGATE) NSLog(@"Stored Data of: %@: %i",[theHouse name], success);
}


/**
 * Is called if the Application entered Foreground
 */
- (void) appEnteredForeground:(id) sender {
  if (DEBUG_APP_DELEGATE) NSLog(@"Application entered Foreground");
}



/**
 * Load the house data from disk
 */
- (void)loadDataFromDisk {
  // Unarchive house object from file is done in init
  House *theHouse = [House sharedHouse];
  if (DEBUG_APP_DELEGATE) NSLog(@"House Name: %@ loaded", theHouse.name);
}



@end
