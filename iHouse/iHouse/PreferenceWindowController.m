//
//  PreferenceWindowController.m
//  iHouse
//
//  Created by Benjamin Völker on 08/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "PreferenceWindowController.h"

@interface PreferenceWindowController ()

@end

@implementation PreferenceWindowController
@synthesize delegate;

- (void)windowDidLoad {
  [super windowDidLoad];
    
  // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(windowWillClose)
                                               name:NSWindowWillCloseNotification
                                             object:nil];
  // This window is not allowed to be fullscreen
  [self.window setCollectionBehavior:NSWindowCollectionBehaviorDefault];
  NSWindowCollectionBehavior behavior = [self.window collectionBehavior];
  behavior ^= NSWindowCollectionBehaviorFullScreenPrimary;
  behavior ^= NSWindowCollectionBehaviorFullScreenDisallowsTiling;
  [self.window setCollectionBehavior:behavior];
  //[self.window setStyleMask:[self.window styleMask] & ~NSResizableWindowMask];
}


-(void)windowWillClose{
  [delegate preferencesDidClose];
}
@end
