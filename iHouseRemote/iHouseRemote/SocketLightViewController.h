//
//  SocketLightViewController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 26/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "House.h"

@interface SocketLightViewController : UIViewController {
  Device *device;
}

@property (weak, nonatomic) IBOutlet UIImageView *deviceImage;
@property (weak, nonatomic) IBOutlet UISegmentedControl *switchSegmentControl;

-(id)initWithDevice:(Device*)theDevice;

- (void)switchButtonPressed:(id)sender;


@end
