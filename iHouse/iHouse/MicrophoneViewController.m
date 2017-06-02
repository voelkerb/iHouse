//
//  MicrophoneViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "MicrophoneViewController.h"
#import "MicrophoneStreamHandler.h"
#import "IDevice.h"
#define STATUS_IDLE_LABEL @"Idle"
#define STATUS_MIC_LABEL @"Streaming Mic data"
#define STATUS_AUDIO_LABEL @"Streaming Audio data"

#define BUTTON_SPEAKER_ON @"Speaker On"
#define BUTTON_SPEAKER_OFF @"Speaker Off"
#define BUTTON_MIC_ON @"Mic On"
#define BUTTON_MIC_OFF @"Mic Off"

#define ALERT_BUTTON_OK @"Ok"
#define ALERT_NO_CONNECTION_MESSAGE @"Mic device not connected"
#define ALERT_NO_CONNECTION_MESSAGE_INFORMAL @"Connect an iHouse mic to enable this feature."
#define ALERT_NO_SIM_CONNECTION_MESSAGE @"Streaming to other Mic"
#define ALERT_NO_SIM_CONNECTION_MESSAGE_INFORMAL @"Simultaneous streaming to other microphones is not possible yet. First stop streaming to the other microphone module"

@interface MicrophoneViewController ()

@end

@implementation MicrophoneViewController
@synthesize iDevice, nameLabel, microImage, backView, statusMsgLabel, speakerToggleButton;


/*
 * For copying this view
 */
-(id)copyWithZone:(NSZone *)zone {
  MicrophoneViewController *copy = [[MicrophoneViewController allocWithZone: zone] initWithDevice:iDevice];
  return copy;
}

- (id)initWithDevice:(IDevice *)theMicrophoneDevice {
  self = [super init];
  if (self && (theMicrophoneDevice.type == microphone)) {
    // Get the pointer of the device
    iDevice = theMicrophoneDevice;
    // Add observer for device edit change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:iDeviceDidChange object:nil];
  }
  return self;
}

// If the device was dedited, we need to redraw
-(void)reDraw:(NSNotification*)notification {
  if ([iDevice isEqualTo:[notification object]]) {
    [self viewDidLoad];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do view setup here.
  // Set name and image of the device
  [nameLabel setStringValue:[iDevice name]];
  [microImage setImage:[iDevice image]];
  
  // Set the background color accordingly
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[[iDevice color] CGColor]];
  [backView setWantsLayer:YES];
  [backView setLayer:viewLayer];
  
    // Init the status msg
  [statusMsgLabel setStringValue:@""];
  
  if ([(Microphone*)[iDevice theDevice] state] == micro_idle) {
    [statusMsgLabel setStringValue:STATUS_IDLE_LABEL];
    [speakerToggleButton setTitle:BUTTON_SPEAKER_ON];
  } else if ([(Microphone*)[iDevice theDevice] state] == micro_transmittingMic) {
    [statusMsgLabel setStringValue:STATUS_MIC_LABEL];
    [speakerToggleButton setTitle:BUTTON_SPEAKER_ON];
  } else if ([(Microphone*)[iDevice theDevice] state] == micro_receivingAudio) {
    [statusMsgLabel setStringValue:STATUS_AUDIO_LABEL];
    [speakerToggleButton setTitle:BUTTON_SPEAKER_OFF];
  }
}

/*
 * Toggles the audio streaming state.
 */
- (IBAction)toggleAudio:(id)sender {
  if (![self checkConnected]) return;
  // Depending on the state display the audio state
  if ([(Microphone*)[iDevice theDevice] state] == micro_idle) {
    // Look if any other audio is beeing transmitted
    // Since simultaneous transmitting or receiving of audio is not possible
    // show an alert sheet if so
    MicrophoneStreamHandler *microphoneStreamHandler = [MicrophoneStreamHandler sharedMicrophoneStreamHandler];
    if (microphoneStreamHandler.state != audioStream_idle) {
      NSAlert *alert = [[NSAlert alloc] init];
      [alert addButtonWithTitle:ALERT_BUTTON_OK];
      [alert setMessageText:ALERT_NO_SIM_CONNECTION_MESSAGE];
      [alert setInformativeText:ALERT_NO_SIM_CONNECTION_MESSAGE_INFORMAL];
      [alert setAlertStyle:NSWarningAlertStyle];
      [alert runModal];
      return;
    } else {
      [statusMsgLabel setStringValue:STATUS_AUDIO_LABEL];
      [speakerToggleButton setTitle:BUTTON_SPEAKER_OFF];
      [(Microphone*)[iDevice theDevice] audioOn];
    }
  } else if ([(Microphone*)[iDevice theDevice] state] == micro_receivingAudio) {
    [statusMsgLabel setStringValue:STATUS_IDLE_LABEL];
    [speakerToggleButton setTitle:BUTTON_SPEAKER_ON];
    [(Microphone*)[iDevice theDevice] audioOff];
  }
}


/*
 * Checks if the Mic is connected over USB.
 */
- (BOOL)checkConnected {
  if ([(Microphone*)[iDevice theDevice] isConnected]) return true;
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:ALERT_BUTTON_OK];
  [alert setMessageText:ALERT_NO_CONNECTION_MESSAGE];
  [alert setInformativeText:ALERT_NO_CONNECTION_MESSAGE_INFORMAL];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert runModal];
  return false;
}

@end
