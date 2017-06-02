//
//  RoomPreferenceViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 19/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Room.h"
#import "House.h"
#import "DragDropImageView.h"

// The Functions the delegate has to implement
@protocol RoomPreferenceViewControllerDelegate <NSObject>

// The delegate needs to change something
- (void) roomDidChange;

@end

@interface RoomPreferenceViewController : NSViewController

// The delegate variable
@property (weak) id<RoomPreferenceViewControllerDelegate> delegate;

// The room variable
@property (strong) Room *room;

// The outlets (name, image and colorwell)
@property (weak) IBOutlet NSTextField *nameTextField;
@property (weak) IBOutlet DragDropImageView *imageView;
@property (weak) IBOutlet NSColorWell *colorWell;

// The scrollview and its inside view
@property (weak) IBOutlet NSView *previewView;

@property (strong) NSViewController *roomViewController;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
                                    room: (Room *)theRoom;

// If Outlets changed
- (IBAction)nameTextFieldChanged:(id)sender;
- (IBAction)imageChanged:(id)sender;
- (IBAction)colorChanged:(id)sender;

@end
