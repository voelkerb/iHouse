//
//  SingleIRCommandViewController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 27/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

// The Functions the delegate has to implement
@protocol SingleIRCommandViewControllerDelegate <NSObject>

// The delegate needs to change something
- (void)pressedButton:(NSString*)command;

@end

@interface SingleIRCommandViewController : UIViewController {
  UIImage *commandImage;
}

// The delegate variable
@property (weak) id<SingleIRCommandViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *toggleButton;
@property NSString *commandName;

-(id)initWithCommandName:(NSString *)theCommandName andImage:(UIImage *)image;


- (IBAction)toggleButtonPressed:(id)sender;

@end
