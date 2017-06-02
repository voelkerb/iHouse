//
//  MainAppGeneralViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 15/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "MainAppGeneralViewController.h"
#import "UndockedWindowController.h"
#import "MainAppViewController.h"


#define DEBUG_GENERAL_VIEW 1
#define UNDOCK_BUTTON_WIDTH 18
#define UNDOCK_BUTTON_HEIGHT 18
#define UNDOCK_IMAGE_NAME @"undock_256.png"
#define HEADLINE_STRING_GROUPS @"Groups:"
#define HEADLINE_HEIGHT  24
#define SCROLLER_WIDTH 10
#define GROUPS_PER_ROW 2
// The Dimensions of the tiles
#define TILE_WIDTH 500
#define TILE_HEIGHT 360
#define TILE_MARGIN_X 10
#define TILE_MARGIN_Y 10

@interface MainAppGeneralViewController ()

@end

@implementation MainAppGeneralViewController
@synthesize documentView, scrollView;


-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    // Subscribe notifications if groups changed, we need to redraw then
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:GroupAdded object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:GroupRemoved object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:GroupChanged object:nil];
    
    // Subscribe notification, if one wants to undock a view
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableUndock:) name:UndockNotificationDisable object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableUndock:) name:UndockNotificationEnable object:nil];
    
    
    // Add a frame change observer since we eventually have to change the scroller of scrollviews
    [[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(viewChanged)
                                             name:NSViewFrameDidChangeNotification
                                           object:self.view];
  }

  return self;
}

/*
 * If the user wants to undock a view
 */
-(void)enableUndock:(NSNotification*)notification {
  NSLog(@"Enable Undock");
  for (NSButton* button in undockButtons) {
    [button setHidden:NO];
  }
}

/*
 * If the user finished undocking
 */
-(void)disableUndock:(NSNotification*)notification {
  NSLog(@"Disable Undock");
  for (NSButton* button in undockButtons) {
    [button setHidden:YES];
  }
}

/*
 * If the user changed e.g. the groups we need to fully redraw
 */
-(void)reDraw:(NSNotification*)notification {
  [self drawViews];
  [self viewChanged];
}

/*
 * If the user changed the size of the view. The scroller needs to be reset
 */
-(void)viewChanged {
  // Get the subviews and iterate over all
  NSArray *subviews = [[NSArray alloc] initWithArray:[documentView subviews]];
  for (NSScrollView *view in subviews) {
    // If we have a scrollview here
    if ([view isKindOfClass:[NSScrollView class]]) {
      // Get the document view
      NSView *theDocumentView = [view documentView];
      // If the documentview + the start of the scrollview is smaller than the height, we need no scroller
      if (theDocumentView.frame.size.height + view.frame.origin.y < documentView.frame.size.height) {
        [view setHasVerticalScroller:NO];
        [view setVerticalScrollElasticity:NSScrollElasticityNone];
        // Else we need a scroller
      } else {
        [view setHasVerticalScroller:YES];
        [view setVerticalScrollElasticity:NSScrollElasticityAutomatic];
      }
    }
  }
}

/*
 * If this view is inited
 */
- (void)viewDidLoad {
  // This view is width and height sizable
  self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  // Make background color a little bit darker so that groups are visible
  [scrollView setWantsLayer:YES];
  CALayer *layer = [[CALayer alloc] init];
  layer.backgroundColor = [[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:0.1 alpha:0.1] CGColor];
  [scrollView setLayer:layer];
  // We haven't init till now
  initDone = false;
  // Add views to display in this array
  viewControllers = [[NSMutableArray alloc] init];
  windowControllers = [[NSMutableArray alloc] init];
  undockButtons = [[NSMutableArray alloc] init];
  
  
  documentView = [[NSFlippedView alloc] init];
  
  // The scroll view has no Border
  [scrollView setBorderType:NSNoBorder];
  [scrollView setHasVerticalScroller:YES];
  //[scrollView setHas]
  [scrollView setHasHorizontalScroller:YES];
  [scrollView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
  //[documentView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
  [documentView setFrame:NSMakeRect(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
  [scrollView setDocumentView:documentView];
  
  [super viewDidLoad];
}

/*
 * If view has layout its subviews, we can draw the views (but not if we resized)
 */
-(void)viewDidLayout {
  // If not inited, draw the views
  if (!initDone){
    //[self drawAllViews];
    [self drawViews];
    [self viewChanged];
    initDone = true;
 }
}

/*
 * Draws all views.
 */
- (void) drawViews {
  // Remove all current views
  NSArray *subviews = [[NSArray alloc] initWithArray:[documentView subviews]];
  for (NSView *subview in subviews) [subview removeFromSuperview];
  [viewControllers removeAllObjects];
  
  // Start positions
  NSInteger xPos = TILE_MARGIN_X;
  NSInteger yPos = TILE_MARGIN_Y;
  
  // If we have groups in this house, display them
  if ([[[House sharedHouse] groups] count] > 0) {
    // The rect for the Headline view
    NSRect headlineFrame = NSMakeRect(2*TILE_MARGIN_X, TILE_MARGIN_Y , SCROLLER_WIDTH, HEADLINE_HEIGHT);
    // The rect for the scroll view
    NSRect scrollFrame = NSMakeRect(TILE_MARGIN_X, 4*TILE_MARGIN_Y , SCROLLER_WIDTH, documentView.frame.size.height - 6*TILE_MARGIN_Y);
    
    // Get total width of this view (depends on number of groups)
    NSInteger numberOfGroups = [[[House sharedHouse] groups] count];
    // Get the width and height of the group view
    GroupActivateViewController *dummy = [[GroupActivateViewController alloc] initWithGroup:[[[House sharedHouse] groups] firstObject]];
    NSInteger tileWidth = dummy.view.frame.size.width;
    NSInteger tileHeight = dummy.view.frame.size.height;
    // If we have less groups than we want to max have in a row, decrese width
    NSInteger groupViewWidth = numberOfGroups*(tileWidth + TILE_MARGIN_X) + TILE_MARGIN_X;
    // Else we have exactly the number of groups in a row
    if (numberOfGroups > GROUPS_PER_ROW) groupViewWidth = GROUPS_PER_ROW*(tileWidth + TILE_MARGIN_X) + TILE_MARGIN_X;
    // Set the scrollframe width by adding the width of the scroller
    scrollFrame.size.width = groupViewWidth + SCROLLER_WIDTH;
    // Set the headline width
    headlineFrame.size.width = groupViewWidth - 2*TILE_MARGIN_X;
    
    // Set the Group Headline
    NSTextField *headlineText = [[NSTextField alloc] initWithFrame:headlineFrame];
    [headlineText setStringValue:[NSString stringWithFormat:@" %@", HEADLINE_STRING_GROUPS]];
    [documentView addSubview:headlineText];
    [headlineText setEditable:NO];
    [headlineText setBordered:NO];
    
    // Init scrollview for all groups
    NSScrollView *groupScrollView = [[NSScrollView alloc] initWithFrame:scrollFrame];
    // The scrollview is only sizable in height
    [groupScrollView setAutoresizingMask:NSViewHeightSizable];
    // The scrollview does not have any background only vertical scrollers and no boarder
    [groupScrollView setDrawsBackground:NO];
    [groupScrollView setBorderType:NSNoBorder];
    [groupScrollView setHasVerticalScroller:YES];
    
    // The document view of this scrollview has the width of what we want to display, the height is changing
    NSRect documentFrame = NSMakeRect(0, 0, groupViewWidth, tileHeight);
    
    // Get the total height of the group view
    NSInteger groupViewHeight = ceil(numberOfGroups/(float)GROUPS_PER_ROW)
                                    *(dummy.view.frame.size.height + TILE_MARGIN_Y);
    // Set this height to the document frame
    documentFrame.size.height = groupViewHeight;
    
    // The view is of type flippedview to be top aligned in scrollview
    NSFlippedView *groupView = [[NSFlippedView alloc] initWithFrame:documentFrame];
    
    // Set the devices view as the document view of the scrollview
    [groupScrollView setDocumentView:groupView];
    
    // This frame will be looped over all groups
    NSRect groupFrame = NSMakeRect(TILE_MARGIN_X, 0, 0, 0);
    // Count the groups
    NSInteger groupCounter = 0;
    // Loop over all Groups
    for (Group *theGroup in [[House sharedHouse] groups]) {
      // Alloc viewcontroller of gorup
      GroupActivateViewController *groupViewController = [[GroupActivateViewController alloc] initWithGroup:theGroup];
      // Store viewcontroller in array
      [viewControllers addObject:groupViewController];
      
      // Get width and height of the group view
      groupFrame.size.width = groupViewController.view.frame.size.width;
      groupFrame.size.height = groupViewController.view.frame.size.height;
      // Set its frame and add it as a subview of the view of all groups
      [groupViewController.view setFrame:groupFrame];
      [groupView addSubview:[self makeUndockAble:groupViewController.view withTag:viewControllers.count]];
      // Increase x origin and group counter
      groupFrame.origin.x += groupFrame.size.width + TILE_MARGIN_X;
      groupCounter++;
      // If we are at the end of the row, reset groupcounter
      // Reset x position and increment y position to start new row
      if (groupCounter == GROUPS_PER_ROW) {
        groupCounter = 0;
        groupFrame.origin.y += groupFrame.size.height + TILE_MARGIN_Y;
        groupFrame.origin.x = TILE_MARGIN_X;
      }
    }
    
    // Adding the scrollview to the horizontally scrollable view
    [documentView addSubview:groupScrollView];
    
    // Set overall x Position
    xPos += groupScrollView.frame.size.width;
  }
  
  // Show weather and calendard
  WeatherViewController *weatherViewController = [[WeatherViewController alloc] initWithBgColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.05]];
  NSRect frame = [[weatherViewController view] frame];
  frame.origin.x = xPos;
  frame.origin.y = yPos;
  [[weatherViewController view] setFrame:frame];
  [viewControllers addObject:weatherViewController];
  [documentView addSubview:[self makeUndockAble:[weatherViewController view] withTag:viewControllers.count]];
  // Increment y position so that calendar is displayed under weather
  yPos += frame.size.height + TILE_MARGIN_Y;
  
  
  CalendarViewController *calenderViewController = [[CalendarViewController alloc] initWithBgColor:[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.05]];
  frame = [[calenderViewController view] frame];
  
  frame.origin.x = xPos;
  frame.origin.y = yPos;
  
  [[calenderViewController view] setFrame:frame];
  [viewControllers addObject:calenderViewController];
  [documentView addSubview:[self makeUndockAble:[calenderViewController view] withTag:viewControllers.count]];
  
  // Increment positions
  xPos += frame.size.width + TILE_MARGIN_X;
  yPos += frame.size.height + TILE_MARGIN_Y;
  
  
  [documentView setFrame:NSMakeRect(0, 0, xPos, yPos)];
  
}

-(NSView*)makeUndockAble:(NSView*)theView withTag:(NSInteger)theTag {
  NSView *boarderedView = [[NSView alloc] initWithFrame:theView.frame];
  [theView setFrame:NSMakeRect(0, 0, theView.frame.size.width, theView.frame.size.height)];
  NSButton *undockButton = [[NSButton alloc] initWithFrame:
                            NSMakeRect(boarderedView.frame.size.width - UNDOCK_BUTTON_WIDTH - 2, 0,
                                       UNDOCK_BUTTON_WIDTH, UNDOCK_BUTTON_HEIGHT)];
  [undockButton setTitle:@""];
  [undockButton setBordered:NO];
  [undockButton setNeedsDisplay:YES];
  [undockButton setButtonType:NSMomentaryChangeButton];
  [undockButton setImage:[NSImage imageNamed:UNDOCK_IMAGE_NAME]];
  [undockButton setTarget: self];
  [undockButton setAction: @selector(undockPressed:)]; //invisible is a selector see below
  [undockButton setTag:theTag];
  [undockButton setHidden:YES];
  [[undockButton cell] setImageScaling:NSImageScaleProportionallyDown];
  
  [boarderedView addSubview:theView];
  [boarderedView addSubview:undockButton];
  
  [undockButtons addObject:undockButton];
  //[[calenderViewController view] setFrame:frame];
  
  // This is not sizable at all
  //[[calenderViewController view] setAutoresizingMask:NSViewNotSizable];
  
  [boarderedView setAutoresizingMask:NSViewNotSizable];
  return boarderedView;
  
}

-(void)undockPressed:(id)sender {
  // Get index of the corresponding viewcontroller in the array
  NSInteger index = [sender tag]-1;
  // If tag is not correct return
  if (index < 0 || index >= [viewControllers count]) return;
  NSLog(@"undock it %li", index);
  // Get view controller
  NSViewController *viewController = [viewControllers objectAtIndex:index];
    
  
  UndockedWindowController *windowController = [[UndockedWindowController alloc] initWithViewController:viewController];
  
  // Make it to frontmost window
  [[windowController window] makeKeyAndOrderFront:self];

  [windowControllers addObject:windowController];
}


@end
