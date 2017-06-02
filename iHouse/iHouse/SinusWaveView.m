//
//  SISinusWaveView.m
//
//  Created by Raffael Hannemann on 12/28/13.
//  Copyright (c) 2013 Raffael Hannemann. All rights reserved.
//  Edited by Benjamin Völker
//

#import "SinusWaveView.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudio.h>

@implementation SinusWaveView {
	NSTimer *_levelTimer;
}
- (id) initWithCoder:(nonnull NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    // Set up default values
    _frequency = 1.5;
    _phase = 0;
    _amplitude = 5.0;
    _waveColor = [NSColor whiteColor];
    _backgroundColor = [NSColor clearColor];
    _idleAmplitude = 0.05;
    _dampingFactor = 0.8;
    _waves = 5;
    _phaseShift = -0.19;
    _density = 15.0;
    _marginLeft = 10;
    _marginRight = 10;
    _oscillating = true;
    _lineWidth = 2.0;
    self.listen = YES;
    
    // Create a recorder instance, recording to /dev/null to trash the data immediately
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    NSError *error = nil;
    _recorder = [[AVAudioRecorder alloc] initWithURL:url settings:@{
                                                                    AVSampleRateKey: @8000,
                                                                    AVFormatIDKey: @(kAudioFormatAppleLossless),
                                                                    AVNumberOfChannelsKey: @1,
                                                                    AVEncoderAudioQualityKey: @(AVAudioQualityMax)
                                                                    } error:&error];
    
    if (!_recorder || error) {
      NSLog(@"WARNING: %@ could not create a recorder instance (%@).", self, error.localizedDescription);
    } else {
      [_recorder prepareToRecord];
      _recorder.meteringEnabled = YES;
    }
  }
  return self;
}

- (id)initWithFrame:(NSRect)frame
{

	self = [super initWithFrame:frame];
	if (self) {
		// Set up default values
		_frequency = 1.5;
		_phase = 0;
		_amplitude = 5.0;
		_waveColor = [NSColor whiteColor];
		_backgroundColor = [NSColor clearColor];
		_idleAmplitude = 0.1;
		_dampingFactor = 0.8;
		_waves = 5;
		_phaseShift = -0.19;
		_density = 15.0;
		_marginLeft = 0;
		_marginRight = 0;
		_lineWidth = 2.0;
    self.listen = YES;
    _oscillating = true;
		
    
		// Create a recorder instance, recording to /dev/null to trash the data immediately
		NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
		NSError *error = nil;
		_recorder = [[AVAudioRecorder alloc] initWithURL:url settings:@{
																		AVSampleRateKey: @44100,
																		AVFormatIDKey: @(kAudioFormatAppleLossless),
																		AVNumberOfChannelsKey: @1,
																		AVEncoderAudioQualityKey: @(AVAudioQualityMax)
																		} error:&error];
		
		if (!_recorder || error) {
			NSLog(@"WARNING: %@ could not create a recorder instance (%@).", self, error.localizedDescription);
		} else {
			[_recorder prepareToRecord];
			_recorder.meteringEnabled = YES;
		}
	}
	return self;
}


#pragma mark - Customize the Audio Plot
-(void)awakeFromNib {
	[self setListen:YES];
  
}

- (void) setListen:(BOOL)listen {
	_listen = listen;
	if (_listen) {
		[_recorder record];
		if (_levelTimer)
			[_levelTimer invalidate];
		_levelTimer = [NSTimer scheduledTimerWithTimeInterval:0.025 target:self selector:@selector(recorderDidRecord:) userInfo: nil repeats: YES];
		
	} else {
		[_recorder stop];
		if (_levelTimer)
			[_levelTimer invalidate];
		_amplitude = 0;
	}
	[self setNeedsDisplay:YES];
}

- (void) recorderDidRecord: (NSTimer *) timer {
	[_recorder updateMeters];
  
	int requiredTickes = 2; // Alter this to draw more or less often
	tick = (tick+1)%requiredTickes;
  
  // Calculate Voltage level from power data
  float value = 18* pow(10, 0.05*[_recorder averagePowerForChannel:0]);/// > 0.05 ? 0.1 : 0;
  // Constraint it between 0.1 and 1.0
  if (value < 0.1) {
    value = 0;
    _oscillatingThreshold = false;
  } else {
    _oscillatingThreshold = true;
  }
  if (value > 1) value = 1;
  
  _amplitude = value;
  
	_phase += _phaseShift;
	
	[self setNeedsDisplay:tick==0];
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
	if ([self isHidden])
		return;
	
	if (!(self.window.occlusionState & NSWindowOcclusionStateVisible))
		return;
	
	if (_clearOnDraw) {
		[_backgroundColor set];
		NSRectFill(self.bounds);
	}
	
	float halfHeight = NSHeight(self.bounds)/2;
	float width = NSWidth(self.bounds)-_marginLeft-_marginRight;
	float mid = width /2.0;
	float stepLength = _density / width;
	
	// We draw multiple sinus waves, with equal phases but altered amplitudes, multiplied by a parable function.
	for(int i=0;i<_waves+1;i++) {
		
		[[NSGraphicsContext currentContext] saveGraphicsState];
		NSGraphicsContext * nsGraphicsContext = [NSGraphicsContext currentContext];
		CGContextRef context = (CGContextRef) [nsGraphicsContext graphicsPort];
		
		// The first wave is drawn with a 2px stroke width, all others a with 1px stroke width.
		CGContextSetLineWidth(context, (i==0)? _lineWidth:_lineWidth*.5 );
		
		const float maxAmplitude = halfHeight-4; // 4 corresponds to twice the stroke width
		
		// Progress is a value between 1.0 and -0.5, determined by the current wave idx, which is used to alter the wave's amplitude.
		float progress = 1.0-(float)i/_waves;
		float normedAmplitude = (1.5*progress-0.5)*_amplitude;
		
		[[self colorForLineAtLocation:0 percentalLength:0] set];
		CGContextMoveToPoint(context, 0, halfHeight);
		CGContextAddLineToPoint(context, _marginLeft, halfHeight);
		CGContextStrokePath(context);
		
		CGFloat lastX = _marginLeft;
		CGFloat lastY = halfHeight;
		for(float x = 0; x<width+_density; x+=_density) {
			CGContextMoveToPoint(context, lastX, lastY);
			
			// Scale it normally distributed
      float scaling = exp(-0.5*pow((x-mid), 2)/pow(0.3*mid, 2));

			if (!_oscillating || !_oscillatingThreshold) {
				normedAmplitude = _idleAmplitude;
			}
			float y = scaling *maxAmplitude *normedAmplitude *sinf(2 *M_PI *(x / (width)) *_frequency +_phase) + halfHeight;
			
			CGContextAddLineToPoint(context, x+_marginLeft, y);
			CGFloat location = x/(width+_density);
			
			// Determine the color for this part of the wave, and alter its alpha value
			NSColor *stepColor = [self colorForLineAtLocation:location percentalLength:stepLength];
			CGFloat red = 0;
			CGFloat green = 0;
			CGFloat blue = 0;
			CGFloat alpha = 0;
      if (stepColor == nil) stepColor = [NSColor whiteColor];
			const CGFloat *components = CGColorGetComponents(stepColor.CGColor);
			red = components[0];
			green = components[1];
			blue = components[2];
			alpha = components[3];
			
			NSColor *alteredColor = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha *(progress/3.0*2+1.0/3.0)];
			[alteredColor set];
			
			CGContextStrokePath(context);
			lastX = x+_marginLeft;
			lastY = y;
		}
    NSColor *stepColor = [self colorForLineAtLocation:1.0 percentalLength:0];
    if (stepColor == nil) stepColor = [NSColor whiteColor];

		[stepColor set];
		CGContextMoveToPoint(context, lastX, halfHeight);
		CGContextAddLineToPoint(context, NSWidth(self.bounds), halfHeight);
		CGContextStrokePath(context);
	}
}

- (NSColor *) colorForLineAtLocation: (CGFloat) location percentalLength: (CGFloat) length {
	return self.waveColor;
}

-(void)startListening {
  self.oscillating = true;
}

- (void)stopListening {
  self.oscillating = false;
}

@end
