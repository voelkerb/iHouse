//
//  SettingsViewController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 06/06/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"

@interface SettingsViewController : UIViewController<UITextFieldDelegate> {
  
  CATransition *transition;
}

@property Settings *settings;

@property (weak, nonatomic) IBOutlet UITextField *ipTextField;


@property (weak, nonatomic) IBOutlet UIButton *DoneButton;


- (IBAction)doneButtonPressed:(id)sender;

@end
