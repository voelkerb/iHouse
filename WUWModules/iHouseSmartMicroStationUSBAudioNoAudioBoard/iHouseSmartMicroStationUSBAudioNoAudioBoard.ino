#include <IntervalTimer.h>
#include <RF24.h>
#include <SPI.h>
#include <Audio.h>
#include <SD.h>
#include <Wire.h>
#include <SerialFlash.h>
#include "printf.h"


#define DEBUG 1
#define DEBUG_STREAM 1
#define DEBUG_STREAM_AUDIO 0
#define DEBUG_STREAM_MIC 0

#define SERIAL_SPEED 115200

#define RESPONSE_REQUEST "OK"
#define RESPONSE_COMMAND "/"
#define COMMAND_RESPONSE_REQUEST '?'
#define COMMAND_METER 'm'
#define COMMAND_SWITCH 's'
#define COMMAND_SWITCH_FREETEC 'f'
#define COMMAND_SWITCH_CMI 'c'
#define COMMAND_SNIFF_CMI 'i'
#define COMMAND_SWITCH_CONRAD 'o'
#define COMMAND_START_STREAM 'q'
#define COMMAND_STOP_STREAM 'w'
#define COMMAND_STOP_MICRO 'n'
#define COMMAND_MICRO 'e'
#define COMMAND_OK_HOUSE "okayHouse"

// An array holding the prefix for a serial input/output
#define SERIAL_PREFIXES 0xff, 0xfe
byte serialPrefix[] = {SERIAL_PREFIXES};


// The RF24 Streaming
// The CE and CSN pins of the NRF24
#define CE_PIN  5
#define CSN_PIN 6 

#define AUDIO_STREAM_CHANNEL 1
#define AUDIO_STREAM_DATA_RATE RF24_1MBPS

// Define the transmit pipes
const uint64_t writePipe[5] = { 0xF0F0F0F0D2LL, 0xF0F0F0F0C3LL, 0xF0F0F0F0B4LL, 0xF0F0F0F0A5LL, 0xF0F0F0F096LL };
const uint64_t readPipe[5] = { 0x3A3A3A3AD2LL, 0x3A3A3A3AC3LL, 0x3A3A3A3AB4LL, 0x3A3A3A3AA5LL, 0x3A3A3A3A96LL };
const uint64_t broadcastPipe = { 0xF0F0F0F087LL };
// Create a Radio
RF24 audioStream(CE_PIN, CSN_PIN);

// Pin for start stop streaming button
#define BUTTON_PIN A7


// If currently streaming
bool streamMic = false;
bool streamAudio = false;

// GUItool: begin automatically generated code
AudioInputAnalog         theADC;           //xy=718,134
AudioRecordQueue         audioRecorder;         //xy=281,63
AudioConnection          patchCord2(theADC, audioRecorder);
AudioControlSGTL5000     sgtl5000;     //xy=265,212
// GUItool: end automatically generated code

// Audio buffer and its indices
#define AUDIO_BUFFER_SIZE 256
#define RADIO_BUFFER_SIZE 32
#define RADIO_NUMB_BUFFERS 2
// Buffer for one audio block
byte audioRecordBuffer[AUDIO_BUFFER_SIZE];
byte audioBlockBuffer[AUDIO_BUFFER_SIZE];
byte audioSerialBuffer[2*AUDIO_BUFFER_SIZE];
// Radio Buffer holding two payloads
uint8_t radioBuffer[RADIO_NUMB_BUFFERS][RADIO_BUFFER_SIZE];
uint8_t whichRadioBuffer = 0;

void setup() {
  // Init pins
  pinMode(BUTTON_PIN, INPUT);
    
  // Init serial debugging
  Serial.begin(SERIAL_SPEED);
  //while (!Serial.dtr()){}
  Serial1.begin(SERIAL_SPEED);
  
  // Delay to let Teensy enter serial console
  delay(2000);
  
  // Audio connections require memory, and the record queue
  // uses this memory to buffer incoming audio.
  AudioMemory(60);
  
  audioRecorder.begin();
  
  // Init the audioStream
  initAudioStream();
  
  if (DEBUG) {
    delay(100);
    Serial.println("Setup done!");
    Serial.flush();
    delay(100);
  }
}

void loop() {
  // Update Streaming Mode
  updateStreamMode();

  // Stream data if needed
  handleOutgoingStream();
  
  // Read data if available
  handleIncomingStream();
    
  // Route Serial from 2nd uC if currently not receiving mic data
  if (!streamMic) {
    while(Serial1.available()) Serial.write(Serial1.read());
  }
}

elapsedMillis micReset;

// Reads data from the incoming stream if available
void handleIncomingStream() {
  if (streamAudio) return;
  uint8_t pipe_num;
  // If Serial data is available and greater equal the buffer size
  if (audioStream.available(&pipe_num)) {
    // Reset the mic present timer
    if (!streamMic && Serial.dtr()) {
      Serial.print(RESPONSE_COMMAND);
      Serial.print(COMMAND_MICRO);
      Serial.print(COMMAND_OK_HOUSE);
      Serial.println(pipe_num);
      Serial.flush();
      delay(10);
    }
    micReset = 0;
    streamMic = true;
    if (DEBUG_STREAM_AUDIO) {
      Serial.print("New audio data available from: ");
      Serial.println(pipe_num);
    }
    // Read the complete buffer at once (faster than to read single bytes)
    audioStream.read(radioBuffer[whichRadioBuffer], RADIO_BUFFER_SIZE);
    // Increment buffer index
    whichRadioBuffer++;
    // If buffer index greater than # buffers reset buffer index
    if (whichRadioBuffer >= RADIO_NUMB_BUFFERS) {
      whichRadioBuffer = 0;            
      // Copy radio buffer data to serial buffer 
      
      if (Serial.dtr()) {
        memcpy(&audioSerialBuffer[0], radioBuffer[0], RADIO_BUFFER_SIZE);
        memcpy(&audioSerialBuffer[RADIO_BUFFER_SIZE], radioBuffer[1], RADIO_BUFFER_SIZE);
        // Write audio data over serial as 2 payloads
        //Serial.write(radioBuffer[0], RADIO_BUFFER_SIZE);
        //Serial.write(radioBuffer[1], RADIO_BUFFER_SIZE);
        Serial.write(audioSerialBuffer, 2*RADIO_BUFFER_SIZE);
      }
    }
  }
  if (micReset > 200) {
    streamMic = false;
  }
}



// Streams Mic data if needed
void handleOutgoingStream() {
  if (!streamAudio) return;
  // If the audio recorder has new data
  if (audioRecorder.available()) {
    if (DEBUG_STREAM_AUDIO) Serial.println("Send recorded audio Block");
    // Fetch one audioBlock
    memcpy(audioRecordBuffer, audioRecorder.readBuffer(), AUDIO_BUFFER_SIZE);
    // Free this audio Block
    audioRecorder.freeBuffer();
    int j = 0;
    
    // ********* 8BIT, 22KHz *********** //
    for (int i = 1; i < 128; i+=4) {
      int8_t value = audioRecordBuffer[i];
      //Serial.println(value);
      radioBuffer[0][j] = value;
      j++;
    }
    j = 0;
    for (int i = 129; i < 256; i+=4) {
      int8_t value = audioRecordBuffer[i];
      //Serial.println(value);
      radioBuffer[1][j] = value;
      j++;
    }
    
    // Stop listening for radio Data
    audioStream.stopListening();
    // Write the complete buffers at once (much more efficient than to write single bytes)
    // Beware we can only send as much as 3 payloads at once, otherwise the data is flushed
    // before it is send
    audioStream.writeFast(radioBuffer[0], RADIO_BUFFER_SIZE); // writeFast
    //delayMicroseconds(500);
    audioStream.writeFast(radioBuffer[1], RADIO_BUFFER_SIZE); // writeFast
    audioStream.txStandBy();
    // Enable reading again
    audioStream.startListening();  
  }
}


// Init the audio Stream
void initAudioStream() {
  // Since the audio board uses different spi pins, we need to change those here
  SPI.setMOSI(7);
  SPI.setSCK(14);
  // Settings of the NRF24
  // Begin radio
  audioStream.begin();
  // Set rf-channel (must be same on receiver side)
  audioStream.setChannel(AUDIO_STREAM_CHANNEL);
  // Disable Acknowledgement to fasten communication
  // TODO: it is enabled here to get acknowledge for every write fast
  audioStream.setAutoAck(1);
  // Set speed to fastest possible
  audioStream.setDataRate(AUDIO_STREAM_DATA_RATE);//RF24_1MBPS//RF24_2MBPS//RF24_250KBPS
  // Set crc check length
  audioStream.setCRCLength(RF24_CRC_8);
  // Open the reading pipeline
  audioStream.openReadingPipe(1,readPipe[0]);
  audioStream.openReadingPipe(2,readPipe[1]);
  audioStream.openReadingPipe(3,readPipe[2]);
  audioStream.openReadingPipe(4,readPipe[3]);
  audioStream.openReadingPipe(5,readPipe[4]);
  audioStream.openWritingPipe(broadcastPipe);
  // Leave low poer mode
  audioStream.powerUp();
  // Show configuration of the RF Module on startup
  if (DEBUG_STREAM) audioStream.printDetails();
  // Begin listening
  audioStream.startListening();
}

// Updates the streaming mode Streaming/noStreaming
void updateStreamMode() {
  // Debounce button
  if (!digitalRead(BUTTON_PIN)) {
    delay(100);
    if (!digitalRead(BUTTON_PIN)) {
      while(!digitalRead(BUTTON_PIN)) {}
      // Change streaming mode
      streamAudio = !streamAudio;
      if (DEBUG_STREAM) {
        if (streamAudio) Serial.println("Start streaming mic data.");
        else Serial.println("Stop streaming mic data.");
      }
      // If streaming should be enabled
      if (streamAudio) {
        // Clear all recorded audio
        audioRecorder.clear();
        audioRecorder.begin();
        audioStream.stopListening();
        // For Button press, open broadcast Pipe
        //audioStream.openWritingPipe(broadcastPipe);
        if (audioStream.available()) {
          Serial.println("Clear");
          uint8_t dummy[32];
          while (audioStream.available()) {
            // Read payload
            audioStream.read(dummy, 32);
          }
        }
        audioStream.openWritingPipe(broadcastPipe);
        streamMic = false;
      // If streaming should be disabled
      } else {
        audioStream.startListening();
      }
    }
  }
}

// Handler for a serial input.
void serialEvent() {
  // Check for new input (must be greater Prefix size).
  if (Serial.available() > (int)sizeof(serialPrefix)) {
    // Check if the prefix array matches
    // Inputs from other devices that don't meet the
    // used prefix are ignored
    for (int i = 0; i < (int)sizeof(serialPrefix); i++) {
      if (serialPrefix[i] != Serial.read()) return;
    }
    char input = Serial.read();
    // Check the input. 
    switch (input) {
      case COMMAND_RESPONSE_REQUEST: {
        Serial.println(RESPONSE_REQUEST);
        break;
      }
      case COMMAND_START_STREAM:  {
        while (!Serial.available()) {}
        uint8_t pipe_num = Serial.read()-'0';
        if (DEBUG) {
          Serial.print("Sending Data to station: ");
          Serial.println(pipe_num);
        }
        if (pipe_num > 5 || pipe_num < 0) return;
        // Clear all recorded audio
        audioRecorder.clear();
        audioRecorder.begin();
         
        audioStream.stopListening();
        if (audioStream.available()) {
          Serial.println("Clear");
          uint8_t dummy[32];
          while (audioStream.available()) {
            // Read payload
            audioStream.read(dummy, 32);
          }
        }
        
        if (pipe_num == 0) {
          audioStream.openWritingPipe(broadcastPipe);
        } else {
          audioStream.openWritingPipe(writePipe[pipe_num - 1]);
        }
        
        streamAudio = true;
        streamMic = false;
        break;
      }
      case COMMAND_STOP_STREAM: {
        audioStream.startListening();
        streamAudio = false;
        break;
      }
      // TODO: Test and implement
      case COMMAND_STOP_MICRO: {
        while (!Serial.available()) {}
        uint8_t pipe_num = Serial.read()-'0';
        if (DEBUG) {
          Serial.print("Stopping station: ");
          Serial.println(pipe_num);
        }
        if (pipe_num > 5 || pipe_num < 0) return;
         
        audioStream.stopListening();
        if (audioStream.available()) {
          Serial.println("Clear");
          uint8_t dummy[32];
          while (audioStream.available()) {
            // Read payload
            audioStream.read(dummy, 32);
          }
        }
        
        if (pipe_num == 0) {
          audioStream.openWritingPipe(broadcastPipe);
        } else {
          audioStream.openWritingPipe(writePipe[pipe_num - 1]);
        }
          // Write dummy data so that micros stops
        uint8_t dummy2[32] = {0};
        for (int i = 0; i < 3; i++) {
          audioStream.writeFast(dummy2, RADIO_BUFFER_SIZE); // writeFast
          //delayMicroseconds(500);
          audioStream.writeFast(dummy2, RADIO_BUFFER_SIZE); // writeFast
          audioStream.txStandBy();
        }
        audioStream.startListening();
        streamMic = false;
        break;
      }
      // This is a command for the 2nd microcontroller connected over Serial1
      default: {
        Serial.println("Serial Bridge SmartEnergy");
        // Delay to buffer all serial commands
        delay(10);
        // write Prefix
        Serial1.write(serialPrefix, sizeof(serialPrefix));
        // Command
        Serial1.print(input);
        // And rest if there is any
        while (Serial.available()) {
          Serial1.write(Serial.read());
        }
      }
    }
  }
}

