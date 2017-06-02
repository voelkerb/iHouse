//
//  MainAppRoomViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 15/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "MainAppRoomViewController.h"
#import "MainAppViewController.h"
#import "UndockedWindowController.h"

// The width and height of the House scroll view are the screen dimensions minus the side- and topbar
#define ROOM_SCROLLVIEW_MAX_HEIGHT [[NSScreen mainScreen] frame].size.height - 40
#define ROOM_SCROLLVIEW_MAX_WIDTH [[NSScreen mainScreen] frame].size.width - 150

#define UNDOCK_BUTTON_WIDTH 18
#define UNDOCK_BUTTON_HEIGHT 18
#define UNDOCK_IMAGE_NAME @"undock_256.png"
#define DEVICE_WIDTH 150
#define DEVICE_HEIGHT 250
#define DEVICE_MARGIN_X 20
#define DEVICE_MARGIN_Y 10
#define DEVICE_START_MARGIN_X 10
#define DEVICE_START_MARGIN_Y 40
#define SCROLLER_WIDTH 10
#define HEADLINE_MARGIN_Y 10
#define HEADLINE_HEIGHT 20
#define HEADLINE_STRING_ENDING @" Devices:"

@interface MainAppRoomViewController ()

@end

@implementation MainAppRoomViewController
@synthesize viewThatScrolls, scrollView, room;



/*
 * Init the Room properly with a name
 */
- (nullable instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
                                    room: (nullable Room *) theRoom {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  
  if (self) {
    // Store name for further processing
    room = theRoom;
    undockButtons = [[NSMutableArray alloc] init];
    windowControllers = [[NSMutableArray alloc] init];
    
    // Notifications for new background color and for new device
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomBgChanged:) name:RoomBackgroundDidChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomDeviceChanged:) name:RoomDeviceDidChange object:nil];
    // Add a frame change observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewChanged)
                                                 name:NSViewFrameDidChangeNotification
                                               object:self.view];
    
    // Subscribe notification, if one wants to undock a view
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableUndock:) name:UndockNotificationDisable object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableUndock:) name:UndockNotificationEnable object:nil];
  }
  
  return self;
}

/*
 * If the user changed the size of the view. The scroller needs to be reset
 */
-(void)viewChanged {
  // Get the subviews and iterate over all
  NSArray *subviews = [[NSArray alloc] initWithArray:[viewThatScrolls subviews]];
  for (NSScrollView *view in subviews) {
    // If we have a scrollview here
    if ([view isKindOfClass:[NSScrollView class]]) {
      // Get the document view
      NSView *documentView = [view documentView];
      // If the documentview + the start of the scrollview is smaller than the height, we need no scroller
      if (documentView.frame.size.height + view.frame.origin.y < viewThatScrolls.frame.size.height) {
        [view setHasVerticalScroller:NO];
        [view setVerticalScrollElasticity:NSScrollElasticityNone];
        // Else we need a scrooler
      } else {
        [view setHasVerticalScroller:YES];
        [view setVerticalScrollElasticity:NSScrollElasticityAutomatic];
      }
    }
  }
}


/*
 * If the room added or removed a view, the room needs to redraw.
 */
-(void)roomDeviceChanged:(NSNotification*)notification {
  if ([room isEqualTo:[notification object]]) {
    NSArray *subviews = [[NSArray alloc] initWithArray:[viewThatScrolls subviews]];
    for (NSView *view in subviews) [view removeFromSuperview];
    [self initDeviceViews];
  }
}

/*
 * If the background color of the room was changed, readraw the background only
 */
-(void)roomBgChanged:(NSNotification*)notification {
  if ([[room name] isEqualToString:[(Room*)[notification object] name]]) {
    // Set the background color accordingly
    CALayer *viewLayer2 = [CALayer layer];
    [viewLayer2 setBackgroundColor:[[room color] CGColor]];
    [scrollView setWantsLayer:YES];
    [scrollView setLayer:viewLayer2];
  }
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

- (void)viewDidLoad {
  self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  
  // Init the scrollview to be borderless, vertical and horizontal sizeable and set its views size/height
  [self initScrollView];
  [self initDeviceViews];
  
  
  [super viewDidLoad];
}

/*
 * Init the scrollview and set the background color correctly.
 */
- (void) initScrollView {
  // The scroll view has no Border
  [scrollView setBorderType:NSNoBorder];
  [scrollView setHasVerticalScroller:NO];
  //[scrollView setHas]
  [scrollView setHasHorizontalScroller:YES];
  [scrollView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
  [viewThatScrolls setAutoresizingMask:NSViewHeightSizable];
  [viewThatScrolls setFrame:NSMakeRect(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
  [scrollView setDocumentView:viewThatScrolls];
  
  // Set the background color accordingly
  CALayer *viewLayer2 = [CALayer layer];
  [viewLayer2 setBackgroundColor:[[room color] CGColor]];
  [scrollView setWantsLayer:YES];
  [scrollView setLayer:viewLayer2];
}


/*
 * Add all available devices in the room view, sorted after the device type.
 */
- (void) initDeviceViews {
  // Storing all viewcontroller in array
  viewControllers = [[NSMutableArray alloc] init];
  // Get a copy of all available devices with device type as key
  NSDictionary *devices = [room sortedDevices];
  
  // The rect for the Headline view, starting on the left side
  NSRect headlineFrame = NSMakeRect(DEVICE_START_MARGIN_X, HEADLINE_MARGIN_Y , DEVICE_WIDTH + SCROLLER_WIDTH, HEADLINE_HEIGHT);
  
  // The rect for the scroll view, starting on the left side
  NSRect scrollFrame = NSMakeRect(DEVICE_START_MARGIN_X, DEVICE_START_MARGIN_Y , DEVICE_WIDTH + SCROLLER_WIDTH, viewThatScrolls.frame.size.height - DEVICE_START_MARGIN_Y - 2*DEVICE_MARGIN_Y);
  
  // Go through all device types
  for (DeviceType theType = light; theType < differentDeviceCount; theType++) {
    // Store type of the dummy device
    // Dummy device to get the device type as string
    IDevice *dummy = [[IDevice alloc] initWithDeviceType:theType];
    if ([dummy deviceTypeHasActions:dummy.type]) {
      // Get all devices with this type
      NSArray *devicesOfSameType = [devices objectForKey:[dummy DeviceTypeToString:theType]];
      // If there is device we need to draw it's view
      if (devicesOfSameType != nil && [devicesOfSameType count] > 0) {
        //NSLog(@"%@: %@", [dummy DeviceTypeToString:theType], devicesOfSameType);
        // Add one scrollview for each device type with the correct width
        
        // Get with and height of the device
        //NSView *deviceViewAndSize = [dummy deviceViewAndSize];
        NSViewController *deviceViewController = [dummy deviceView];
        NSInteger tileWidth = deviceViewController.view.frame.size.width;
        NSInteger tileHeight = deviceViewController.view.frame.size.height;
        scrollFrame.size.width = tileWidth + SCROLLER_WIDTH;
        headlineFrame.size.width = tileWidth;
        
        // Set the headlineView
        NSTextField *headlineText = [[NSTextField alloc] initWithFrame:headlineFrame];
        [headlineText setStringValue:[NSString stringWithFormat:@" %@%@",[dummy DeviceTypeToString:theType], HEADLINE_STRING_ENDING]];
        [viewThatScrolls addSubview:headlineText];
        [headlineText setEditable:NO];
        [headlineText setBordered:NO];
        
        NSScrollView *deviceTypeScrollView = [[NSScrollView alloc] initWithFrame:scrollFrame];
        // The scrollview is only sizable in height
        [deviceTypeScrollView setAutoresizingMask:NSViewHeightSizable];
        // The scrollview does not have any background only vertical scrollers and no boarder
        [deviceTypeScrollView setDrawsBackground:NO];
        [deviceTypeScrollView setBorderType:NSNoBorder];
        [deviceTypeScrollView setHasVerticalScroller:YES];
        
        // The document view has the width and height of a device view
        NSRect documentFrame = NSMakeRect(0, 0, tileWidth, tileHeight);
        
        // We need to make things different if we have a device that has different heights and width
        if ([dummy deviceViewHasDifferentSize]) {
          NSInteger scrollHeight = 0;
          NSInteger scrollWidth = 0;
          for (IDevice *theDevice in devicesOfSameType) {
            NSView *deviceView = [theDevice deviceView].view;
            // Increment height of scrollview by height of device
            scrollHeight += deviceView.frame.size.height;
            // If width is greater than currently biggest width restore
            if (scrollWidth < deviceView.frame.size.width) scrollWidth = deviceView.frame.size.width;
          }
          // Set width and height of the document frame
          documentFrame.size.height = [devicesOfSameType count]*(DEVICE_MARGIN_Y) + scrollHeight - DEVICE_MARGIN_Y;
          documentFrame.size.width = scrollWidth;
        } else {
          // The height is the number of devices plus the margins between the devices
          documentFrame.size.height = [devicesOfSameType count]*(DEVICE_MARGIN_Y + tileHeight) - DEVICE_MARGIN_Y;
        }
        // The view is of type flippedview to be top aligned in scrollview
        NSFlippedView *deviceTypeView = [[NSFlippedView alloc] initWithFrame:documentFrame];
        
        // Set the devices view as the document view of the scrollview
        [deviceTypeScrollView setDocumentView:deviceTypeView];
        
        
        // The frame of each device has the size of the device view
        NSRect deviceFrame = NSMakeRect(0, 0, DEVICE_WIDTH, DEVICE_HEIGHT);
        // Draw all devices of the same type
        for (IDevice *theDevice in devicesOfSameType) {
          if ([theDevice deviceView]) {
            // Get the view of the device
            NSViewController *viewController = [theDevice deviceView];
            // Store in array so that it a copy of it is held here
            [viewControllers addObject:viewController];
            NSView *deviceView = viewController.view;
            // Get width and height of the device
            deviceFrame.size.width = viewController.view.frame.size.width;
            deviceFrame.size.height = viewController.view.frame.size.height;
            // Set its frame and add it as a subview of the view of all devices of this kind
            [deviceView setFrame:deviceFrame];
            [deviceTypeView addSubview:[self makeUndockAble:deviceView withTag:viewControllers.count]];
            //[deviceTypeView addSubview:deviceView];
            deviceFrame.origin.y += deviceFrame.size.height + DEVICE_MARGIN_Y;
          }
        }
        
        // Adding the scrollview to the horizontally scrollable view
        [viewThatScrolls addSubview:deviceTypeScrollView];
        
        // Increment the x positon to display the next device type next to the current
        scrollFrame.origin.x += tileWidth + SCROLLER_WIDTH + DEVICE_MARGIN_X;
        headlineFrame.origin.x += tileWidth + SCROLLER_WIDTH + DEVICE_MARGIN_X;
      }
    }
    
    // Set the width of the scroll view after setting up every device
    NSRect newRect = viewThatScrolls.frame;
    newRect.size.width = scrollFrame.origin.x;
    [viewThatScrolls setFrame:newRect];
  }
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
