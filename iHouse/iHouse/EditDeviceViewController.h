//
//  EditDeviceViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 20/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "House.h"
#import "DragDropImageView.h"

// The Functions the delegate has to implement
@protocol EditDeviceViewControllerDelegate <NSObject>

// The delegate needs to change something
- (void) deviceDidChange;

@end

@interface EditDeviceViewController : NSViewController

// The delegate variable
@property (weak) id<EditDeviceViewControllerDelegate> delegate;

// The room variable
@property (strong) IDevice *device;

// The outlets (name, image and colorwell)
@property (weak) IBOutlet NSTextField *nameTextField;
@property (weak) IBOutlet DragDropImageView *imageView;
@property (weak) IBOutlet NSColorWell *colorWell;
@property (weak) IBOutlet NSBox *theBox;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
                                    device: (IDevice*)theDevice;

// If Outlets changed
- (IBAction)nameTextFieldChanged:(id)sender;
- (IBAction)imageChanged:(id)sender;
- (IBAction)colorChanged:(id)sender;

@end
