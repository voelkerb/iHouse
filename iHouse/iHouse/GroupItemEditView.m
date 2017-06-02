//
//  GroupItemEditView.m
//  iHouse
//
//  Created by Benjamin Völker on 15/03/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "GroupItemEditView.h"
#import "House.h"
#define DEBUG_GROUP_EDIT_VIEW 1

@interface GroupItemEditView ()

@end

@implementation GroupItemEditView
@synthesize delegate, groupItem, devicePopUp, actionPopUp, ItemNumber;


-(id)initWithGroupItem:(GroupItem *)theGroupItem andNumber:(NSInteger)theNumber {
  if (self = [super init]) {
    groupItem = theGroupItem;
    number = theNumber;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [ItemNumber setStringValue:[NSString stringWithFormat:@"%li:", number]];
  
  [devicePopUp removeAllItems];
  [actionPopUp removeAllItems];
  
  
  for (Room *theRoom in [[House sharedHouse] rooms]) {
    for (IDevice *theDevice in [theRoom devices]) {
      if ([theDevice deviceTypeHasSelectors:theDevice.type] && [theDevice voiceCommandSelectors] && [[theDevice voiceCommandSelectors] count] > 0) {
        [devicePopUp addItemWithTitle:[theDevice name]];
        // If this is the current device name display available selectors
        if ([groupItem.device.name isEqualToString:[theDevice name]]) {
          [actionPopUp removeAllItems];
          NSArray *selectors = [[NSArray alloc] initWithArray:[theDevice voiceCommandSelectors]];
          NSArray *selectorsReadable = [[NSArray alloc] initWithArray:[theDevice voiceCommandSelectorsReadable]];
          if (DEBUG_GROUP_EDIT_VIEW) NSLog(@"Available Selectors: %@", selectors);
          
          NSInteger i = 0;
          for (NSString *selector in selectorsReadable) {
            [actionPopUp addItemWithTitle:selector];
            [[actionPopUp lastItem] setTag:i];
            if ([[selectors objectAtIndex:i] isEqualToString:groupItem.selector]) {
              [actionPopUp selectItemWithTag:i];
            }
            i++;
          }
        }
      }
    }
  }
  if (![groupItem.device.name isEqualToString:KeyGroupStandardSelector]) {
    [devicePopUp selectItemWithTitle:groupItem.device.name];
  } else {
    [devicePopUp selectItemAtIndex:-1];
  }
  // Highlight selected selector.
  if ([[groupItem selector] isEqualToString:KeyGroupStandardSelector]) {
    [actionPopUp selectItemAtIndex:-1];
  }
}

- (IBAction)actionPopUpChanged:(id)sender {
  if (DEBUG_GROUP_EDIT_VIEW) NSLog(@"ActionPopup Changed to: %@", [[actionPopUp selectedItem] title]);
  
  for (Room *theRoom in [[House sharedHouse] rooms]) {
    for (IDevice *theDevice in [theRoom devices]) {
      if ([groupItem.device.name isEqualToString:[theDevice name]]) {
        NSArray *selectors = [[NSArray alloc] initWithArray:[theDevice voiceCommandSelectors]];
        if ([selectors objectAtIndex:[[actionPopUp selectedItem] tag]]) {
          groupItem.selector =[selectors objectAtIndex:[[actionPopUp selectedItem] tag]];
          if (DEBUG_GROUP_EDIT_VIEW) NSLog(@"Selector: %@", groupItem.selector);
          
        }
      }
    }
  }
}

- (IBAction)devicePopUpChanged:(id)sender {
  if (DEBUG_GROUP_EDIT_VIEW) NSLog(@"DevicePopup Changed to: %@", [[devicePopUp selectedItem] title]);
  for (Room *theRoom in [[House sharedHouse] rooms]) {
    for (IDevice *theDevice in [theRoom devices]) {
      if ([[[devicePopUp selectedItem] title] isEqualToString:[theDevice name]]) {
        [groupItem setDevice:theDevice];
        if (DEBUG_GROUP_EDIT_VIEW) NSLog(@"Set device: %@", [theDevice name]);
        [actionPopUp removeAllItems];
        NSArray *selectors = [[NSArray alloc] initWithArray:[theDevice voiceCommandSelectorsReadable]];
        if (DEBUG_GROUP_EDIT_VIEW) NSLog(@"Available Selectors: %@", selectors);
        NSInteger i = 0;
        for (NSString *selector in selectors) {
          [actionPopUp addItemWithTitle:selector];
          [[actionPopUp lastItem] setTag:i];
          i++;
        }
      }
    }
  }
  [actionPopUp selectItemAtIndex:-1];
  
}

- (IBAction)removePressed:(id)sender {
  if (delegate) [delegate groupItemRemoved:self];
}
@end
