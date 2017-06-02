//
//  EditSpeakerViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Speaker.h"

@interface EditSpeakerViewController : NSViewController

@property (strong) Speaker *speaker;

- (id) initWithSpeaker:(Speaker*) theSpeaker;

@end
