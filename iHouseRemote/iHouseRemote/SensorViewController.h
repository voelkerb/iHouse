//
//  SensorViewController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 27/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "House.h"

@interface SensorViewController : UIViewController{
  Device *device;
}

@property (weak, nonatomic) IBOutlet UIImageView *deviceImage;
@property (weak, nonatomic) IBOutlet UILabel *dataLabel;

-(id)initWithDevice:(Device*)theDevice;

@end
