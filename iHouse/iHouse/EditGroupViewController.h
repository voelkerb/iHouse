//
//  EditGroupViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 15/03/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Group.h"
#import "GroupItemEditView.h"

// The Functions the delegate has to implement
@protocol EditGroupViewControllerDelegate <NSObject>

// The delegate needs to change something
- (void) groupDidChange;

@end

@interface EditGroupViewController : NSViewController<GroupItemEditViewControllerDelegate> {
  NSMutableArray *viewControllers;
}

// The delegate variable
@property (weak) id<EditGroupViewControllerDelegate> delegate;

// The room variable
@property (strong) Group *group;
// The outlets (name, image and colorwell)
@property (weak) IBOutlet NSTextField *nameTextField;
@property (weak) IBOutlet DragDropImageView *imageView;
@property (weak) IBOutlet NSScrollView *devicesAndActionsScrollView;


-(id)initWithGroup:(Group*)theGroup;
// If Outlets changed
- (IBAction)nameTextFieldChanged:(id)sender;
- (IBAction)imageChanged:(id)sender;
- (IBAction)addGroupItem:(id)sender;
- (IBAction)testGroup:(id)sender;

@end
