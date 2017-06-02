//
//  MeterViewController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 27/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "House.h"

@interface MeterViewController : UIViewController{
  Device *device;
}

@property (weak, nonatomic) IBOutlet UIImageView *deviceImage;
@property (weak, nonatomic) IBOutlet UILabel *meterDataLabel;

-(id)initWithDevice:(Device*)theDevice;

@end
