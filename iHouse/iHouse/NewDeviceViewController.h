//
//  newDeviceViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 20/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "House.h"
#import "DragDropImageView.h"

// The Functions the delegate has to implement
@protocol NewDeviceViewControllerDelegate <NSObject>

// The delegate needs to change something
- (void) newDeviceFinished;

@end
@interface NewDeviceViewController : NSViewController

// The delegate variable
@property (weak) id<NewDeviceViewControllerDelegate> delegate;

// The view of the Device
@property (weak) IBOutlet NSView *createDeviceView;

// The popup buttons for for which room and which device
@property (weak) IBOutlet NSPopUpButton *roomPopUpButton;
@property (weak) IBOutlet NSPopUpButton *deviceTypePopUpButton;
// The text field containing the name
@property (weak) IBOutlet NSTextField *nameTextField;
// The colorwell containing the color of the new device
@property (weak) IBOutlet NSColorWell *colorWell;
// The image of the new device
@property (weak) IBOutlet DragDropImageView *image;

// The House and device object
@property (strong) House *house;
@property (strong) IDevice *device;
@property (strong) NSViewController *advancedDeviceEditView;


// If the User choose differently
- (IBAction)popUpButtonChanged:(id)sender;
- (IBAction)nameTextFieldChanged:(id)sender;

// Save or Cancel the new device
- (IBAction)cancelPressed:(id)sender;
- (IBAction)savePressed:(id)sender;

@end
