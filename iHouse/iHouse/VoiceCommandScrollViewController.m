//
//  VoiceCommandScrollViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 09/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "VoiceCommandScrollViewController.h"
#import "NSFlippedView.h"

#define WELCOME_MSG_FONTSIZE 50
#define TEXT_FONTSIZE 30
#define WELCOME_MSG @"What can I help you with?"
#define APPEND_VIEW_MARGIN 10
#define SEPERATOR_HEIGHT 50

#define ROOM_WELCOME_MSG @"Room:"
#define ROOM_WELCOME_MSG_FONTSIZE 30

#define MAX_VIEWS 50


@implementation VoiceCommandScrollViewController
@synthesize responseScrollView;

- (id)initWithScrollView:(NSScrollView *)theScrollView {
  if (self = [super init]) {
    views = [[NSMutableArray alloc] init];
    viewControllers = [[NSMutableArray alloc] init];
    responseScrollView = theScrollView;
    // Init the scrollview to be borderless, vertical and horizontal sizeable and set its views size/height
    [responseScrollView setBorderType:NSNoBorder];
    [responseScrollView setHasVerticalScroller:YES];
    [responseScrollView setHasHorizontalScroller:NO];
    [responseScrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
  }
  return self;
}

/*
 * On reinit, an observer for size changes need to be added and the welcome msg should be displayed
 */
- (void)reInitWithRoomName:(NSString*)theRoomName {
  // Add an observer to center the welcome message
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(scrollViewSizeChanged)
                                               name:NSViewFrameDidChangeNotification
                                             object:self.responseScrollView];
  // Display welcome message
  currentlyDisplaysWelcomMsg = true;
  roomName = theRoomName;
  [self setWelcomeMessage];
}


/*
 * Observer for scrollviewsize changed. The scrollview needs to redisplay.
 */
- (void)scrollViewSizeChanged {
  // If no welcome message, draw all subviews
  if (!currentlyDisplaysWelcomMsg) [self drawScrollView];
  // Else set the welcome message
  else [self setWelcomeMessage];
}

/*
 * Appends a give text with the given alignment into the scrollview.
 */
- (void)appendText:(NSString*) theText :(NSTextAlignment) textAlignment :(BOOL) autoScroll {
  // Set the textview to be not editable and with the correct textstyle
  CGRect textFrame = NSMakeRect(0, 0, responseScrollView.frame.size.width, TEXT_FONTSIZE + 8);
  NSTextField *theTextView = [[NSTextField alloc] initWithFrame:textFrame];
  [theTextView setAutoresizingMask:NSViewWidthSizable];
  [theTextView setBordered:NO];
  [theTextView setStringValue:theText];
  [theTextView setEditable:NO];
  [theTextView setLineBreakMode:NSLineBreakByWordWrapping];
  NSFont *font = [NSFont fontWithName:@"HelveticaNeue" size:TEXT_FONTSIZE];
  // Right aligned text should have a lighter font
  if (textAlignment == NSTextAlignmentRight) font = [NSFont fontWithName:@"HelveticaNeue-Light" size:TEXT_FONTSIZE];
  [theTextView setFont:font];
  [theTextView setAlignment:textAlignment];
  
  // Look if truncation the text
  NSRect expansionRect = [[theTextView cell] expansionFrameWithFrame: theTextView.frame inView: theTextView];
  BOOL truncating = !NSEqualRects(NSZeroRect, expansionRect);
  // While truncating, add a new row for the textfield
  while (truncating) {
    NSRect newFrame = [theTextView frame];
    newFrame.size.height += TEXT_FONTSIZE + 8;
    [theTextView setFrame:newFrame];
    expansionRect = [[theTextView cell] expansionFrameWithFrame: theTextView.frame inView: theTextView];
    truncating = !NSEqualRects(NSZeroRect, expansionRect);
  }
  
  // If too many views in scrollview, remove the oldest
  if ([views count] > MAX_VIEWS) {
    // If the view to remove has a viewcontroller, remove this as well
    if ([[[viewControllers objectAtIndex:0] view] isEqualTo:[views objectAtIndex:0]]) [viewControllers removeObjectAtIndex:0];
    [views removeObjectAtIndex:0];
  }
  // Insert the new view and redraw
  [views addObject:theTextView];
  // On autoscroll store new scrollpoint (the origin of the view is changed in [self drawScrollView])
  if (autoScroll) scrollPointView = theTextView;
  [self drawScrollView];
}

/*
 * Appends a View to the scrollView
 */
- (void)appendView:(NSView *)theView :(NSTextAlignment)textAlignment :(BOOL) autoScroll {
  // If too many views in scrollview, remove the oldest
  if ([views count] > MAX_VIEWS) {
    // If the view to remove has a viewcontroller, remove this as well
    if ([[[viewControllers objectAtIndex:0] view] isEqualTo:[views objectAtIndex:0]]) [viewControllers removeObjectAtIndex:0];
    [views removeObjectAtIndex:0];
  }
  // Insert the new view and redraw
  NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0,0,responseScrollView.frame.size.width, theView.frame.size.height)];
  if (textAlignment == NSTextAlignmentCenter) {
    NSRect rect = theView.frame;
    rect.origin.x = responseScrollView.frame.size.width/2 - theView.frame.size.width/2;
    [theView setFrame:rect];
  } else if (textAlignment == NSTextAlignmentRight) {
    NSRect rect = theView.frame;
    rect.origin.x = responseScrollView.frame.size.width - theView.frame.size.width;
    [theView setFrame:rect];
  }
  [view addSubview:theView];
  [views addObject:view];
  // On autoscroll store new scrollpoint (the origin of the view is changed in [self drawScrollView])
  if (autoScroll) scrollPointView = view;
  [self drawScrollView];
}


/*
 * Appends a View to the scrollView
 */
- (void)appendViewWithController:(NSViewController *)theViewController :(NSTextAlignment)textAlignment :(BOOL) autoScroll {
  // If too many views in scrollview, remove the oldest
  if ([views count] > MAX_VIEWS) {
    // If the view to remove has a viewcontroller, remove this as well
    if ([[[viewControllers objectAtIndex:0] view] isEqualTo:[views objectAtIndex:0]]) [viewControllers removeObjectAtIndex:0];
    [views removeObjectAtIndex:0];
  }
  // Add the viewcontroller object
  [viewControllers addObject:theViewController];
  NSView *theView = theViewController.view;
  // Insert the new view and redraw
  NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0,0,responseScrollView.frame.size.width, theView.frame.size.height)];
  if (textAlignment == NSTextAlignmentCenter) {
    NSRect rect = theView.frame;
    rect.origin.x = responseScrollView.frame.size.width/2 - theView.frame.size.width/2;
    [theView setFrame:rect];
  } else if (textAlignment == NSTextAlignmentRight) {
    NSRect rect = theView.frame;
    rect.origin.x = responseScrollView.frame.size.width - theView.frame.size.width;
    [theView setFrame:rect];
  }
  [view addSubview:theView];
  [views addObject:view];
  // On autoscroll store new scrollpoint (the origin of the view is changed in [self drawScrollView])
  if (autoScroll) scrollPointView = view;
  [self drawScrollView];
}

/*
 * Appends a seperator with defined size to the scrollview.
 */
- (void)appendSeperator {
  CGRect seperatorFrame = NSMakeRect(0, 0, responseScrollView.frame.size.width, SEPERATOR_HEIGHT);
  NSView *seperatorView = [[NSView alloc] initWithFrame:seperatorFrame];
  // If too many views in scrollview, remove the oldest
  if ([views count] > MAX_VIEWS) {
  // If the view to remove has a viewcontroller, remove this as well
    if ([[[viewControllers objectAtIndex:0] view] isEqualTo:[views objectAtIndex:0]]) [viewControllers removeObjectAtIndex:0];
    [views removeObjectAtIndex:0];
  }
  // Insert the new view and redraw
  [views addObject:seperatorView];
  [self drawScrollView];
}

/*
 * Redraws the whole scrollview.
 */
- (void)drawScrollView {
  // If was currentlyDisplaying the welcome message, set variable to false
  if (currentlyDisplaysWelcomMsg) currentlyDisplaysWelcomMsg = false;
  // The documentFrame
  NSRect completeFrame = NSMakeRect(0, 0, responseScrollView.frame.size.width, 0);
  // Get the height of the complete documentview
  for (NSView *theView in views) {
    // Set new height of documentview
    completeFrame.size.height += theView.frame.size.height + APPEND_VIEW_MARGIN;
  }
  // The lastView should be visible
  NSView *lastView = [views lastObject];
  // A dummyView, so that the lastView is on the top of the scrollview and the srollview can be displayed correctly
  NSView *dummyViewBottomScroll = [[NSView alloc] initWithFrame:
                                   NSMakeRect(0, 0, responseScrollView.frame.size.width,
                                              responseScrollView.frame.size.height - lastView.frame.size.height - APPEND_VIEW_MARGIN)];
  // Add the height of the dummyView also to the document frame size
  completeFrame.size.height += dummyViewBottomScroll.frame.size.height;
  
  // The documentview is flipped. 0,0 is in the upper left
  NSFlippedView *document = [[NSFlippedView alloc] initWithFrame:completeFrame];
  
    // The frame of each view
  NSRect viewFrame = NSMakeRect(0, 0, responseScrollView.frame.size.width, 0);
  // Go through all views
  for (NSView *theView in views) {
    // Set new height of frame and set the frame
    viewFrame.size.height = theView.frame.size.height;
    viewFrame.size.width = theView.frame.size.width;
    [theView setFrame:viewFrame];
    // Add the view to the scrollview
    [document addSubview:theView];
    // Increment y value for next view
    viewFrame.origin.y += theView.frame.size.height + APPEND_VIEW_MARGIN;
  }
  // Set the height for the dummy view, set its frame and add the document view to the scrollview
  viewFrame.size.height = dummyViewBottomScroll.frame.size.height;
  [dummyViewBottomScroll setFrame:viewFrame];
  [document addSubview:dummyViewBottomScroll];
  // The documentview can be sized horizontal
  [document setAutoresizingMask:NSViewWidthSizable];
  [responseScrollView setDocumentView:document];

  // ScrollToCorrect point
  [[responseScrollView contentView] scrollToPoint: NSMakePoint(0, scrollPointView.frame.origin.y)];
  [responseScrollView reflectScrolledClipView:[responseScrollView contentView]];
}


/*
 * Set the welcome Message centered.
 */
- (void)setWelcomeMessage {
  // Make a view with the size of the scrollview
  NSView *view = [[NSView alloc] initWithFrame:responseScrollView.frame];
  // Make a frame centered in this view
  CGRect textFrame = NSMakeRect(0, 0, view.frame.size.width, WELCOME_MSG_FONTSIZE + 8);
  textFrame.origin.y = view.frame.size.height/2 - textFrame.size.height/2;
  // Init a textfield in the centered frame and set it width sizeable
  NSTextField *welcomeText = [[NSTextField alloc] initWithFrame:textFrame];
  [welcomeText setAutoresizingMask:NSViewWidthSizable];
  [welcomeText setEditable:NO];
  [welcomeText setBordered:NO];
  [welcomeText setStringValue:WELCOME_MSG];
  [welcomeText setLineBreakMode:NSLineBreakByWordWrapping];
  [welcomeText setFont:[NSFont fontWithName:@"HelveticaNeue-UltraLight" size:WELCOME_MSG_FONTSIZE]];
  [welcomeText setAlignment:NSCenterTextAlignment];
  textFrame.origin.y -= textFrame.size.height;
  // Display the room in which the voice command was activated. If this was no room, just print nothing
  if (![roomName isEqualToString:VoiceCommandAnyRoom]) {
    NSTextField *roomText = [[NSTextField alloc] initWithFrame:textFrame];
    [roomText setAutoresizingMask:NSViewWidthSizable];
    [roomText setEditable:NO];
    [roomText setBordered:NO];
    [roomText setStringValue:[NSString stringWithFormat:@"%@ %@", ROOM_WELCOME_MSG, roomName]];
    [roomText setLineBreakMode:NSLineBreakByWordWrapping];
    [roomText setFont:[NSFont fontWithName:@"HelveticaNeue-UltraLight" size:ROOM_WELCOME_MSG_FONTSIZE]];
    [roomText setAlignment:NSCenterTextAlignment];
    [view addSubview:roomText];
  }
  
  // Add the textfield to the view and the view as the documentview of the scrollview
  [view addSubview:welcomeText];
  [responseScrollView setDocumentView:view];
}


@end
