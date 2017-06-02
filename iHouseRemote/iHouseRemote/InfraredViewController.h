//
//  InfraredViewController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 27/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "House.h"
#import "SingleIRCommandViewController.h"
extern NSString * const IRCommandEmptyCommand;

@interface InfraredViewController : UIViewController<SingleIRCommandViewControllerDelegate> {
  Device *device;
  NSMutableArray *viewControllers;
  bool init;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIImageView *deviceImage;
@property (weak, nonatomic) IBOutlet UILabel *dataLabel;

-(id)initWithDevice:(Device*)theDevice;

@end
