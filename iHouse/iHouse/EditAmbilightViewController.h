//
//  EditAmbilightViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 06.03.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Ambilight.h"
@interface EditAmbilightViewController : NSViewController

// The pointer to the ambilight
@property (strong) Ambilight *ambilight;


// Need to initiated with a ambilight
- (id) initWithAmbilight:(Ambilight*) theAmbilight;
@end
