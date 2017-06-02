//
//  InfraredCommandViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 20/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "InfraredCommand.h"

@interface InfraredCommandViewController : NSViewController {
  BOOL editView;
  NSAlert *learnAlert;
}

// The infrared command
@property (strong) InfraredCommand* irCommand;

// The edit infrared command button
@property (weak) IBOutlet NSButton *editButton;

// The toggle button
@property (weak) IBOutlet NSButton *toggleButton;

-(id)initWithIRCommand:(InfraredCommand*)theIRCommand :(BOOL)isEditView;

// The user pressed the edit button
- (IBAction)editButtonPressed:(id)sender;

// The user pressed the toggle button
- (IBAction)toggleButtonPressed:(id)sender;

@end
