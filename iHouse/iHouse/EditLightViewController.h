//
//  EditLightViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Light.h"

@interface EditLightViewController : NSViewController{
@private
  NSInteger lastLightType;
}

// The pointer to the socket
@property (strong) Light *light;
// The view which depend on the set type
@property (weak) IBOutlet NSView *typeDependingView;
// The view of a cmi device
@property (strong) IBOutlet NSView *cmiView;
// The tristate textfield of the cmi device
@property (weak) IBOutlet NSTextField *cmiCodeTextField;
// The view of a freetec device
@property (strong) IBOutlet NSView *freetecView;
// The view of a conrad device
@property (strong) IBOutlet NSView *conradView;
// The popup button for the group and number of the conrad light
@property (weak) IBOutlet NSPopUpButton *conradGroupPopup;
@property (weak) IBOutlet NSPopUpButton *conradNumberPopup;
// The type popup button switching the views
@property (weak) IBOutlet NSPopUpButton *lightTypePopupButton;
// The alertsheet if the user presses sniff button
@property NSAlert *sniffAlert;

// Need to initiated with a light
- (id) initWithLight:(Light*) theLight;
// If the type popup button changed
- (IBAction)lightTypePopupChanged:(id)sender;
// If the user wants to sniff a cmi device
- (IBAction)cmiSniffButton:(id)sender;
// If the user wants to learn a freetec device
- (IBAction)freetecLearnButton:(id)sender;
// If the user changed the conrad number
- (IBAction)conradNumberChanged:(id)sender;
// If the user changed the conrad group
- (IBAction)conradGroupChanged:(id)sender;

@end
