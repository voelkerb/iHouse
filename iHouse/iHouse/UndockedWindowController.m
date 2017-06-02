//
//  undockedWindowController.m
//  iHouse
//
//  Created by Benjamin Völker on 08/04/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "UndockedWindowController.h"

@interface UndockedWindowController ()

@end

@implementation UndockedWindowController
@synthesize viewController, backView;

- (void)windowDidLoad {
  [super windowDidLoad];
  // Set titlebar transparent
  self.window.titlebarAppearsTransparent = true;
}


-(id)initWithViewController:(NSViewController*)theViewController {
  if (self = [super initWithWindowNibName:@"UndockedWindowController"]) {
    // Make copy of the viewcontroller if the instance supports this
    if ([theViewController respondsToSelector:@selector(copyWithZone:)]) {
      viewController = [theViewController copy];
    // If not, the just use the given viewcontroller
    } else {
      // Get viewController
      viewController = theViewController;
    }
    
    // Get position of view relative to global screen corrdinates
    NSRect viewFrameGlobalCoordinates = theViewController.view.frame;
    NSPoint pointInWindow = [theViewController.view convertPoint:NSMakePoint(0, 0) toView:nil];
    NSRect pointOnScreen = [theViewController.view.window convertRectToScreen:NSMakeRect(pointInWindow.x, pointInWindow.y, 0, 0)];
    viewFrameGlobalCoordinates.origin.x = pointOnScreen.origin.x;
    viewFrameGlobalCoordinates.origin.y = pointOnScreen.origin.y;
    
    // Set the position and size of the new created window
    [self.window setFrame:viewFrameGlobalCoordinates display:YES animate:NO];
    // Hide the title
    self.window.title = @"";
    // Set the frame of the visualeffect view
    [backView setFrame:viewController.view.frame];
    // Block autoresize subviews
    //[backView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    // Add the view to the backview
    [backView addSubview:[viewController view]];
    // And finally the view to window
    [self.window.contentView addSubview:backView];
  }
  return self;
}



@end
