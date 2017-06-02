//
//  ToolBarViewSwitcher.h
//  iHouse
//
//  Created by Benjamin Völker on 06/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface ToolBarViewSwitcher : NSObject

// The view with variable content
@property (weak) IBOutlet NSView *currentView;
// The window
@property (weak) IBOutlet NSWindow *window;
// The complete window
@property (weak) IBOutlet NSView *completeView;

// The current active view controller
@property (strong) NSViewController *currentViewController;

@end
