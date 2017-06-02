//
//  VoiceCommandViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 13/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SinusWaveView.h"
#import "VoiceCommandScrollViewController.h"
#import "VoiceCommandHandler.h"


// The Functions the delegate has to implement
@protocol VoiceCommandViewControllerDelegate <NSObject>

// The delegate needs to close the view
- (void) closeVoiceCommandWindow;

@end


@interface VoiceCommandViewController : NSViewController<VoiceCommandHandlerDelegate> {
  BOOL currentlyDisplaysWelcomMsg;
  BOOL hasClosed;
}

// The delegate variable
@property (weak) id<VoiceCommandViewControllerDelegate> delegate;

// The object that handles voice commands stuff
@property (strong) VoiceCommandHandler *voiceCommandHandler;

// The object that handles adding things to the scrollview
@property (strong) VoiceCommandScrollViewController *voiceCommandView;
// The sinus wave showing microphone response
@property (weak) IBOutlet SinusWaveView *sinusWaveView;
// The scrollView of the command responses
@property (weak) IBOutlet NSScrollView *responseScrollView;

// If the voice recognition should start
- (void)startListening;
// If the voice recognition should start
- (void)startListeningInRoom:(Room*)theRoom;

// IBAction if the close window button is pressed
- (IBAction)closeDictationWindow:(id)sender;

@end
