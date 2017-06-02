//
//  SettingsViewController.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 06/06/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "SettingsViewController.h"

@implementation SettingsViewController
@synthesize settings, ipTextField;

-(void)viewDidLoad {
  transition = nil;
  settings = [Settings sharedSettings];
  ipTextField.text = settings.serverIP;
  [ipTextField setReturnKeyType:UIReturnKeyDone];
  ipTextField.delegate = self;
}

- (IBAction)ipAdressChanged:(id)sender {
  [settings setServerIP:[self.ipTextField text]];
  if (![settings store:self]) {
    if (DEBUG) NSLog(@"Could not store settings");
  }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  [textField resignFirstResponder];
  [ipTextField endEditing:YES];
  [self ipAdressChanged:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  [self ipAdressChanged:self];
  return YES;
}


- (IBAction)doneButtonPressed:(id)sender {
  
  if (!transition) {
    transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    [self.view.window.layer addAnimation:transition forKey:nil];
    
    
    [self dismissViewControllerAnimated:NO completion:nil];
  }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [ipTextField endEditing:YES];
}

@end
