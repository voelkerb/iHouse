//
//  VoiceCommandViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 13/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "VoiceCommandViewController.h"
#import "House.h"
#import "VoiceCommand.h"

#define DEBUG_VOICE_COMMAND true

#define DELAY_DISMISS_VIEW_DISCARD 2
#define DELAY_DISMISS_VIEW_SUCCESS 6
#define DELAY_DISMISS_VIEW_DONE_READING 2


@interface VoiceCommandViewController ()

@end


@implementation VoiceCommandViewController
@synthesize delegate;
@synthesize voiceCommandView, responseScrollView;
@synthesize voiceCommandHandler;
@synthesize sinusWaveView;

- (id)init {
  if (self = [super init]) {
    // Init the voic command handler
    voiceCommandHandler = [[VoiceCommandHandler alloc] init];
    voiceCommandHandler.delegate = self;
  }
  return self;
}


- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Init the scrollview handler
  if (!voiceCommandView) voiceCommandView = [[VoiceCommandScrollViewController alloc] initWithScrollView:responseScrollView];
}


/*
 * If the voice recognizer should start listening in a specific given room.
 */
- (void)startListeningInRoom:(Room*)theRoom {
  // The scrollview needs to redisplay and add some observers again.
  [voiceCommandView reInitWithRoomName:[theRoom name]];
  // Restart the sinuswaveview
  [sinusWaveView startListening];
  // Start the voice recognizer
  [voiceCommandHandler startListeningInRoom:theRoom withDiscard:true];
}

/*
 * If the voice recognizer should start listening.
 */
- (void)startListening {
  // The scrollview needs to redisplay and add some observers again.
  [voiceCommandView reInitWithRoomName:VoiceCommandAnyRoom];
  // Restart the sinuswaveview
  [sinusWaveView startListening];
  // Start the voice recognizer
  [voiceCommandHandler startListening:true];
}

/*
 * If voice command Window should be dismissed (delegate will do this for us)
 */
- (IBAction)closeDictationWindow:(id)sender {
  [self closeWindow];
}

/*
 * Close the window and force the voice recognizer to stop listening and to remove all depending sounds in the queue.
 */
- (void)closeWindow {
  // Remove also all close operations that are called with delate inside the class
  [NSViewController cancelPreviousPerformRequestsWithTarget:self];
  [NSViewController cancelPreviousPerformRequestsWithTarget:self selector:@selector(closeWindow) object:nil];
  [voiceCommandHandler forceStopListening];

  // Let the delegate close our window
  [delegate closeVoiceCommandWindow];
}

#pragma mark voiceCommandHandler delegate

/*
 * The voice command sysnthesizer will speak the given text.
 */
- (void)willSpeakResponse:(NSString *)response {
  // Show the spoken response in the scrollview without scrolling to it
  if (response) [voiceCommandView appendText:response : NSTextAlignmentLeft : false];
  //if (AUTO_DISMISS_VIEW) [self performSelector:@selector(closeWindow) withObject:nil afterDelay:DELAY_DISMISS_VIEW_SUCCESS];
}

/*
 * The speech synthesizer has finished speaking.
 */
- (void)finishSpeakResponse {
  // Close the window after delay
  Settings *setting = [Settings sharedSettings];
  if ([setting voiceResponseAutoDismiss]) [self performSelector:@selector(closeWindow) withObject:nil afterDelay:DELAY_DISMISS_VIEW_DONE_READING];
}

/*
 * The voice command synthesizer got a view to display.
 */
-(void)displayResponseView:(NSView *)responseView {
  // Display the view centered without scrolling down to it
  if (responseView) [voiceCommandView appendView:responseView : NSTextAlignmentCenter : false];
}

/*
 * The voice command synthesizer got a viewController to display.
 */
-(void)displayResponseViewWithController:(NSViewController *)responseViewController {
  if (responseViewController) [voiceCommandView appendViewWithController:responseViewController : NSTextAlignmentCenter : false];
}

/*
 * The voice command recognizer recognized a command succesfully.
 */
- (void)didRecognizeCommand:(NSString *)command {
  // Add a seperator to the scrollView
  [voiceCommandView appendSeperator];
  // Show the spoken command with scrolling in the scrollview and stop the sinuswave
  [voiceCommandView appendText:command : NSTextAlignmentRight : true];
  [sinusWaveView stopListening];
}

/*
 * The voice recognizer was started but did not recognize any command.
 */
- (void)noCommandRecognized {
  // stop the sinusWaveView and close the window
  Settings *setting = [Settings sharedSettings];
  if ([setting voiceResponseAutoDismiss]) [self closeWindow];
  [sinusWaveView stopListening];
}

/*
 * If a command needs further commands.
 */
-(void)commandNeedsFurtherCommands {
  //Start listening with discard
  [voiceCommandHandler startListening:true];
  // Start the sinusWaveView again
  [sinusWaveView startListening];
}

@end
