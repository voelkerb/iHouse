//
//  undockedWindowController.h
//  iHouse
//
//  Created by Benjamin Völker on 08/04/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UndockedWindowController : NSWindowController

// The viewcontroller holding the view which is presented in the window
@property (strong) NSViewController* viewController;
// Backview is a visualeffect view as the background of the viewcontroller
@property (weak) IBOutlet NSVisualEffectView *backView;

-(id)initWithViewController:(NSViewController*)theViewController;

@end
