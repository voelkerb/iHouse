//
//  GroupItemEditView.h
//  iHouse
//
//  Created by Benjamin Völker on 15/03/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Group.h"
#import "GroupItem.h"

// The Functions the delegate has to implement
@protocol GroupItemEditViewControllerDelegate <NSObject>

// The delegate needs to change something
- (void) groupItemDidChange:(NSString*)theName;
- (void) groupItemRemoved:(id)sender;

@end
@interface GroupItemEditView : NSViewController {
  NSInteger number;
}


// The delegate variable
@property (weak) id<GroupItemEditViewControllerDelegate> delegate;

@property (weak) IBOutlet NSPopUpButton *devicePopUp;
@property (weak) IBOutlet NSPopUpButton *actionPopUp;
@property (strong) GroupItem* groupItem;
@property (weak) IBOutlet NSTextField *ItemNumber;

- (id)initWithGroupItem:(GroupItem*)theGroupItem andNumber:(NSInteger)theNumber;

- (IBAction)actionPopUpChanged:(id)sender;
- (IBAction)devicePopUpChanged:(id)sender;
- (IBAction)removePressed:(id)sender;

@end
