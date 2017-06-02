#include "EasyVR.h"
#include "SoftwareSerial.h"
#include <SPI.h>
#include <Audio.h>
#include <SD.h>
#include <Wire.h>
#include <RF24.h>
#include "printf.h"

#define DEBUG true
#define DEBUG_STREAM_AUDIO false

//------------------------------SD_CARD-----------------------------//
#define SDCARD_CS_PIN    10

//------------------------------POTI--------------------------------//
#define VOLUME_POTI_PIN A1

//------------------------------BUTTON------------------------------//
// Defines for the button pin and the delays for the actions
#define BUTTON_PIN A7
#define BUTTON_ACTION_DELAY_STREAM 100
#define BUTTON_ACTION_DELAY_PROGRAM 1000
#define BUTTON_ACTION_DELAY_ERASE_ALL 4000
#define BUTTON_ACTION_DELAY_NONE 6000

//------------------------------LED---------------------------------//
// Define for the LED attached to the easy VR Module
#define LED_GREEN EasyVR::IO3
#define LED_BLUE EasyVR::IO2
#define LED_RED EasyVR::IO1
enum Color {
  red,
  green,
  blue,
  yellow,
  purple,
  white,
  black
};
void setLED(Color theColor);  // prototype


//------------------------------SERIAL------------------------------//
// SerialSpeed and easyVR speed
#define SERIAL_COMSPEED 115200
// Faster serial speeds cause the module to only answer sporadically
#define EASYVR_COMSPEED 9600


//------------------------------EASY_VR-----------------------------//
// Timeout for recognizing wakeup-word
#define RECOGNITION_TIMEOUT 5
// Language for recognition (more important for group 0-15)
#define RECOGNITION_LANGUAGE EasyVR::ENGLISH
// How strict the match must be (EASY, NORMAL (default), HARD, HARDER, HARDEST)
#define RECOGNITION_STRICTNESS EasyVR::NORMAL
// In which group the wakup-words are stored
// Group 0   : Triggers -> quick, many false positives, speaker independent, up to 32 triggers
// Group 1-15: Normal   -> normal, false positives possible, speaker independent, up to 32 wakeup-words
// Group 16  : Passwords-> hard, false negatives, speaker dependent, up to 5 passwords
#define GROUP 15
// The distance of the speaker to the microphone is typically far (more than 2 meters)
#define MIC_SETTINGS EasyVR::FAR_MIC
// The easyVR module
EasyVR easyvr(Serial1);
// Members for easyVR
char name[33];


//------------------------------WAV-FILES---------------------------//
#define SOUND_ADD "add.WAV"
#define SOUND_DELETED "deleted.WAV"
#define SOUND_DIDNT_GET_THAT "didntGet.WAV"
#define SOUND_DONE "done.WAV"
#define SOUND_NOISE "noise.WAV"
#define SOUND_READY "ready.WAV"
#define SOUND_SERVER "server.WAV"
#define SOUND_SIMILAR "similar.WAV"
#define SOUND_SPEAK_NOW "speakNow.WAV"
#define SOUND_SPEAK_AGAIN "speakA.WAV"
#define SOUND_SIRI_START "siriSt.WAV"
#define SOUND_SIRI_STOP "siriStop.WAV"
#define SOUND_SIRI_DISCARD "siriDis.WAV"



//------------------------------AUDIO_BOARD-------------------------//
// GUItool: begin automatically generated code
AudioInputI2S            audioInput;           //xy=105,63
AudioRecordQueue         audioRecorder;         //xy=281,63
AudioOutputI2S           audioOutput;           //xy=470,120
AudioEffectBitcrusher    bitCrusher;
AudioPlayQueue           audioPlayer;
AudioPlaySdWav           memorySound;
AudioMixer4              mixAudioOut;
AudioConnection          c1(memorySound, 0, mixAudioOut, 0);
AudioConnection          c4(audioPlayer, 0, mixAudioOut, 1);
AudioConnection          lineInMonoConn1(audioInput, 1, bitCrusher, 0);
AudioConnection          lineInMonoConn2(bitCrusher, audioRecorder);
AudioConnection          lineOutL(mixAudioOut, 0, audioOutput, 0);
AudioConnection          lineOutR(mixAudioOut, 0, audioOutput, 1);
AudioControlSGTL5000     sgtl5000;     //xy=265,212
// GUItool: end automatically generated code
// Input on the audio shield



//------------------------------MICRO-------------------------------//
bool streamMic = false;
//const int audioInputSource = AUDIO_INPUT_LINEIN;
const int audioInputSource = AUDIO_INPUT_MIC;


//------------------------------NRF24-------------------------------//
// The CE and CSN pins of the NRF24
#define CE_PIN  5
#define CSN_PIN 6 
// The radio channel and data rate
#define AUDIO_STREAM_CHANNEL 1
#define AUDIO_STREAM_DATA_RATE RF24_1MBPS
// The radio number of this Micro
uint8_t radioNumber = 1; //(1-5)
// Define the transmit pipes
const uint64_t readPipe[5] = { 0xF0F0F0F0D2LL, 0xF0F0F0F0C3LL, 0xF0F0F0F0B4LL, 0xF0F0F0F0A5LL, 0xF0F0F0F096LL };
const uint64_t writePipe[5] = { 0x3A3A3A3AD2LL, 0x3A3A3A3AC3LL, 0x3A3A3A3AB4LL, 0x3A3A3A3AA5LL, 0x3A3A3A3A96LL };
const uint64_t broadcastPipe = { 0xF0F0F0F087LL };
// Create a Radio
RF24 audioStream(CE_PIN, CSN_PIN);


//------------------------------AUDIO_REC----------------------------//
// Audio buffer and its indices
#define AUDIO_BUFFER_SIZE 256
#define RADIO_BUFFER_SIZE 32
#define RADIO_NUMB_BUFFERS 2
// Buffer for one audio block
byte audioRecordBuffer[AUDIO_BUFFER_SIZE];
byte audioBlockBuffer[AUDIO_BUFFER_SIZE];
// Radio Buffer holding two payloads
uint8_t radioBuffer[RADIO_NUMB_BUFFERS][RADIO_BUFFER_SIZE];
uint8_t whichRadioBuffer = 0;
#define STREAM_TIMEOUT 10000
elapsedMillis streamTime;

//------------------------------SETUP-------------------------------//
void setup() {
  // Set button pin as input
  pinMode(BUTTON_PIN, INPUT);
  // Enable serial communication
  Serial.begin(SERIAL_COMSPEED);
    
  // Init the easyVR module
  initEasyVR();
  
  // Init the audio Board
  initAudioBoard();
  
  // Init the audioStream
  initAudioStream();
  
  // Init the SD Card
  SD.begin(SDCARD_CS_PIN);
  
  if (DEBUG) Serial.println(F("Setup done"));
  
  // Start recognizing a given group
  easyvr.recognizeCommand(GROUP);
}

//------------------------------LOOP--------------------------------//
void loop() {
  // Updates the volume of the speaker if needed
  updateSpeakerVolume();
  
  // Recognize command
  handleCommandDetection();
  
  // Handle button presses
  handleButton();
  
  // Read data if available
  handleIncomingStream();
  
  // Stream data if needed
  handleOutgoingStream();
}


// Streams Mic data if needed
void handleOutgoingStream() {
  if (!streamMic) return;
  // Automatically stop streaming after timeout
  if (streamTime > STREAM_TIMEOUT) {
    stopStreamingMicDiscard();
  }
  // If the audio recorder has new data
  if (audioRecorder.available()) {
    if (DEBUG_STREAM_AUDIO) Serial.println("Outgoing audio data");
    // Fetch one audioBlock
    memcpy(audioRecordBuffer, audioRecorder.readBuffer(), AUDIO_BUFFER_SIZE);
    // Free this audio Block
    audioRecorder.freeBuffer();
    int j = 0;
    /*
    // ********* 8BIT, 22KHz *********** //
    for (int i = 1; i < 128; i+=4) {
      radioBuffer[0][j] = audioRecordBuffer[i];
      j++;
    }
    j = 0;
    for (int i = 129; i < 256; i+=4) {
      radioBuffer[1][j] = audioRecordBuffer[i];
      j++;
    }*/
    
    // ********* 8BIT, 11KHz *********** //
    for (int i = 1; i < 256; i += 8) {
      radioBuffer[0][j] = audioRecordBuffer[i];
      j++;
    }

    
    // Stop listening for radio Data
    audioStream.stopListening();
    // Write the complete buffers at once (much more efficient than to write single bytes)
    // Beware we can only send as much as 3 payloads at once, otherwise the data is flushed
    // before it is send
    audioStream.writeFast(radioBuffer[0], RADIO_BUFFER_SIZE); // writeFast
    //audioStream.writeFast(radioBuffer[1], RADIO_BUFFER_SIZE); // writeFast
    audioStream.txStandBy();
    // Enable reading again
    audioStream.startListening();  
  }
}


// Reads data from the incoming stream if available
void handleIncomingStream() {
  // If Serial data is available and greater equal the buffer size
  if (audioStream.available()) {
    // If was currently streaming, stop streaming, start listening
    if (streamMic) {
      stopStreamingMic();
      if (DEBUG_STREAM_AUDIO) Serial.println("Stop streaming");
    }
    
    if (DEBUG_STREAM_AUDIO) Serial.println("Incoming audio data");
    // Read the complete buffer at once (faster than to read single bytes)audioStream.read(radioBuffer[whichRadioBuffer], RADIO_BUFFER_SIZE);
    audioStream.read(radioBuffer[whichRadioBuffer], RADIO_BUFFER_SIZE);
    // Increment buffer index
    whichRadioBuffer++;
    // If buffer index greater than # buffers reset buffer index
    if (whichRadioBuffer >= RADIO_NUMB_BUFFERS) {
      whichRadioBuffer = 0;
      // Get a buffer for the audi samples
      int16_t *p = audioPlayer.getBuffer();
      
      // Map 64 Byte from radio to 256 Byte for audio block
      // Audio Block(0, 2, 4, 6 ...) is LSB,
      // Audio Block(1, 3, 5, 7 ...) is MSB,
      // -> For 8 Bit-audio write 128 MSB's,
      // Since we only have 64 Payloads from radio we decrease audio sample rate
      // from 44.1kHz to 22.05kHz -> write every two MSB's the same value
      
      // *********** 8Bit, 22kHz ********** //
      // Build array from first 32 Byte
      int j = 0;
      for (int i = 0; i < RADIO_BUFFER_SIZE; i++) {
        // LSB = 0 on 8 Bit
        audioBlockBuffer[j] = 0;
        // MSB = Radio value
        audioBlockBuffer[j+1] = radioBuffer[0][i];
        // LSB = 0 on 8 Bit
        audioBlockBuffer[j+2] = 0;
        // MSB = Radio value -> here map to 22.05 kHz
        audioBlockBuffer[j+3] = radioBuffer[0][i];
        j+=4;
      }
      // Concate second 32 Byte to the array
      for (int i = 0; i < RADIO_BUFFER_SIZE; i++) {
        // LSB = 0 on 8 Bit
        audioBlockBuffer[j] = 0;
        // MSB = Radio value
        audioBlockBuffer[j+1] = radioBuffer[1][i];
        // LSB = 0 on 8 Bit
        audioBlockBuffer[j+2] = 0;
        // MSB = Radio value -> here map to 22.05 kHz
        audioBlockBuffer[j+3] = radioBuffer[1][i];
        j+=4;
      }
      // Copy the audio block to the playBuffer
      memcpy(p, audioBlockBuffer, AUDIO_BUFFER_SIZE);
      // Play the buffer
      audioPlayer.playBuffer();
    }
  }
}


// Handle all button presses
elapsedMillis buttonTime;
int buttonState = 0;
void handleButton() {
  if (!digitalRead(BUTTON_PIN)) {
    Serial.println("Pressed");
    // Stop the easy vr recognition
    easyvr.stop();
    // Debounce delay
    delay(BUTTON_ACTION_DELAY_STREAM);
    if (!digitalRead(BUTTON_PIN)) {
      delay(200);
      // Waited enough for action 1 -> streaming
      if (DEBUG) Serial.print("1...");
      // LED Color to GREEN -> Streaming
      setLED(green);
      // Reset variables
      buttonTime = 0;
      buttonState = 0;
      // Will wait till Button is released
      while (!digitalRead(BUTTON_PIN)) {
        // If waited enough for action 2 -> adding    
        if (buttonTime > BUTTON_ACTION_DELAY_PROGRAM && buttonState == 0) {
          buttonState = 1;
          if (DEBUG) Serial.print("2...");
          // LED Color to BLUE -> Adding
          setLED(blue);
        // If waited enough for action 3 -> deleting    
        } else if (buttonTime > BUTTON_ACTION_DELAY_ERASE_ALL && buttonState == 1) {
          buttonState = 2;
          if (DEBUG) Serial.print("3...");
          // LED Color to RED -> Deleting
          setLED(red);
        // If waited enough for action 4 -> nothing    
        } else if (buttonTime > BUTTON_ACTION_DELAY_NONE && buttonState == 2) {
          buttonState = 3;
          if (DEBUG) Serial.println("4");
          setLED(white);
        }
      }
      // Handle actions after button is realesed here
      switch (buttonState) {
        // Handle toggle streaming
        case 0:
          if (!streamMic) {
            startStreamingMic();
          } else {
            stopStreamingMicDiscard();
          }
          break;
        case 1:
          stopStreamingMic();
          if (DEBUG) Serial.println("Add new command");
          addWakeupWord();
          setLED(white);
          break;
        case 2:
          stopStreamingMic();
          if (DEBUG) Serial.println("Delete all commands");
          deleteAllWakeupWords();
          setLED(white);
          break;
        case 3:
          if (DEBUG) Serial.println("Misspressed");
          setLED(white);
          break;
      }
    }
    // Restart recognition
    easyvr.recognizeCommand(GROUP);
  }
}

// Add a new wakeup word
void addWakeupWord() {
  
  easyvr.stop();
  int commands = easyvr.getCommandCount(GROUP);
  if (DEBUG) {
    Serial.print("Add Command to existing ");
    Serial.println(commands);
  }
  // Look if memory is left
  bool memoryLeft = false;
  // If commands returned -1 sth went wrong
  if (commands > -1) {
    memoryLeft = easyvr.addCommand(GROUP, commands);
  }
  // If enough memory left, store the new command
  if (memoryLeft) {
      delay(100);
      if (DEBUG) Serial.println("Added sucessfully");
      // Give a reasonable label to the command
      char cmdName[5] = "cmd"; 
      cmdName[3] = commands + '0'; 
      cmdName[4] = '\0'; 
      easyvr.setCommandLabel (GROUP, commands, cmdName);
      if (DEBUG) Serial.println("Speak Command now..."); 
      memorySound.play(SOUND_SPEAK_NOW);
      // Start training the command
      setLED(black);
      delay(200);
      setLED(blue);
      delay(10);
      while(memorySound.isPlaying()) {}
      easyvr.trainCommand(GROUP, commands);
      while (!easyvr.hasFinished()) {}
      if (DEBUG) Serial.println("Speak again..."); 
      memorySound.play(SOUND_SPEAK_AGAIN);
      // Indicate success
      setLED(green);
      delay(1000);
      setLED(black);
      delay(200);
      setLED(blue);
      delay(10);
      while(memorySound.isPlaying()) {}
      // Train command again
      easyvr.trainCommand(GROUP, commands);
      while (!easyvr.hasFinished()) {}
      if (DEBUG) Serial.println("Command trained successfully"); 
      memorySound.play(SOUND_DONE);
      // Indicate success
      setLED(green);
      delay(1000); 
      while(memorySound.isPlaying()) {}    
    } else {
      if (DEBUG) Serial.println("Memory full");
      // Indicate via leds that memory is full
      for (int i = 0; i < 3; i++) {
        setLED(black);
        delay(200);
        setLED(red);
        delay(200);
      }
    }
  setLED(white);
  easyvr.recognizeCommand(GROUP);
}


// Deletes all wakeup words from the easy vr module
void deleteAllWakeupWords() {
  uint8_t commands;
  if (DEBUG) Serial.print("Remove all commands....");
  easyvr.stop();
  // Since this command is not always working, try this until it worked
  while (true) {
    // Get the number of commands in this group
    commands = easyvr.getCommandCount(GROUP);
    // Break if this is empty
    if (commands == 0) break;
    // loop over all commands and remove it
    for (int i = 0; i < commands; i++) {
      easyvr.removeCommand(GROUP, i);
      delay(200);
    }
  }
  memorySound.play(SOUND_DELETED);
  if (DEBUG) Serial.println("All commands removed");
  setLED(black);
  delay(200);
  setLED(red);
  delay(200);
  while(memorySound.isPlaying()) {}
  setLED(white);
  // Start recognizing next command
  easyvr.recognizeCommand(GROUP);
}


// Handles the detection of commands
void handleCommandDetection() {
  // If the board has finished recognizing
  if (easyvr.hasFinished()) {
    // Get command
    int command = easyvr.getCommand();
    // Handle command (is command if greater -1)
    if (command > -1) {
      startStreamingMic();
      
      // Print information about the command
      if (DEBUG) {
        uint8_t training;
        easyvr.dumpCommand(GROUP, command, name, training);
        Serial.println(name);
      }
      // Start streaming mic data
      streamMic = true;  
    } 
    // Start recognizing next command
    easyvr.recognizeCommand(GROUP);
  }
}

// Dumps all existing commands
void dumpCommands() {
   // Look through all groups and if there is a command dump command information
  for (int i = 0; i < 17; i++) {
    int commands = easyvr.getCommandCount(i);
    if (commands > 0) {
      for (int j = 0; j < commands; j++) {
        // Show information about the command
        uint8_t training;
        easyvr.dumpCommand(i, j, name, training);
        Serial.print("Group: ");
        Serial.print(i);
        Serial.print(", Name: ");
        Serial.print(name);
        Serial.print(", Training: ");
        Serial.println(training);
      }
    }
  }
}

// Start streaming mic data
void startStreamingMic() {
  if (streamMic) return;
  streamMic = true;
  easyvr.stop();
  if (DEBUG) Serial.println("Start streaming");
  
  // Look if the Station is currently streaming to us
  delay(2);
  // If so don't stream mic
  if (audioStream.available()) {
    if (DEBUG) Serial.println("Stop Streaming, Station is still streaming");
    stopStreamingMic();
    return;
  }
  // Stop listening
  audioStream.stopListening();
  /*
  // Send dummy data to look if station is available
  audioStream.writeFast(radioBuffer[0], RADIO_BUFFER_SIZE);
  // If station did not receive don't stream mic
  if (!audioStream.txStandBy()) {
    if (DEBUG) Serial.println("No station available");
    audioStream.startListening();  
    stopStreamingMic();
    return;
  } */
  // Play start sound
  memorySound.play(SOUND_SIRI_START);
  // TODO: remove for debugging
  setLED(green);
  delay(200);
  setLED(black);
  delay(200);
  // Set LED back to green
  setLED(green);
  while(memorySound.isPlaying()) {}
  // Clear all recorded audio
  audioRecorder.clear();
  audioRecorder.begin();
  // Stop listening
  audioStream.stopListening();
  // Reset streamtimer
  streamTime = 0;
}

// Stop streaming mic data
void stopStreamingMic() {
  if (!streamMic) return;
  streamMic = false;
  easyvr.stop();
  if (DEBUG) Serial.println("Stop streaming");
  delay(100);
  // Set LED back to white
  setLED(white);
  audioStream.startListening();
  // Start recognizing next command
  easyvr.recognizeCommand(GROUP);
}


// Stop streaming mic data
void stopStreamingMicDiscard() {
  if (!streamMic) return;
  streamMic = false;
  easyvr.stop();
  memorySound.play(SOUND_SIRI_DISCARD);
  if (DEBUG) Serial.println("Stop streaming discarded");
  setLED(red);
  delay(200);
  setLED(black);
  delay(200);
  // Set LED back to white
  setLED(white);
  while(memorySound.isPlaying()) {}
  audioStream.startListening();
  // Start recognizing next command
  easyvr.recognizeCommand(GROUP);
}


// Updates the speaker volume of the line out
elapsedMillis volmsec=0;
void updateSpeakerVolume() {
  // Every 50 ms, adjust the volume
  if (volmsec > 50) {
    float vol = analogRead(VOLUME_POTI_PIN);
    vol = vol / 1023.0;
    // If volume is turned very low, mute lineout and set volume
    // On headphone to max
    if (vol < 0.5) {
      sgtl5000.dacVolume(1.0);
      sgtl5000.volume(vol*2);
      sgtl5000.muteLineout();
    } else {
      sgtl5000.unmuteLineout();
      sgtl5000.dacVolume(vol);
    }
    volmsec = 0;
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
  audioStream.openReadingPipe(2,broadcastPipe);
  audioStream.openReadingPipe(1,readPipe[radioNumber-1]);
  audioStream.openWritingPipe(writePipe[radioNumber-1]);
  // Leave low poer mode
  audioStream.powerUp();
  // Show configuration of the RF Module on startup
  if (DEBUG) audioStream.printDetails();
  // Begin listening
  audioStream.startListening();
}


// Inits the audio board
void initAudioBoard() {
  // Audio connections require memory, and the record queue
  // uses this memory to buffer incoming audio.
  AudioMemory(60);
  
  // Enable the audio shield, select input, and enable output
  sgtl5000.enable();
  sgtl5000.inputSelect(audioInputSource);
  sgtl5000.lineInLevel(5);
  sgtl5000.micGain(40);
  // Disable auto Volume
  sgtl5000.autoVolumeDisable();
  // Set up bitcrusher for 16 Bit and 44.1kHz (TODO: bitcrusher does not do anything atm)
  bitCrusher.bits(16);
  bitCrusher.sampleRate(44100);
}


// Will init the easy vr module
void initEasyVR() {
  Serial1.begin(EASYVR_COMSPEED);
  // Delay for TEENSY
  delay(2000);
  
  // Initialize EasyVR
  while (!easyvr.detect()) {
    if (DEBUG) {
      Serial.println(F("EasyVR not detected!"));
      delay(1000);
    }
  }
  
  // Init LED Colors (LED WHITE)
  easyvr.setPinOutput(LED_GREEN, LOW);
  easyvr.setPinOutput(LED_RED, LOW);
  easyvr.setPinOutput(LED_BLUE, LOW);
  // Set timeout for the module
  easyvr.setTimeout(RECOGNITION_TIMEOUT);
  // Set language for the module
  easyvr.setLanguage(RECOGNITION_LANGUAGE);
  // Set distance to speaker
  easyvr.setMicDistance(MIC_SETTINGS);
  // Set Recognition level (only needed for group 0-15)
  easyvr.setLevel(RECOGNITION_STRICTNESS);
  // Init LED Colors (LED WHITE)
  setLED(white);
  // Show existing commands
  dumpCommands();
}

// Set the color of the LED
void setLED(Color theColor) {
  switch(theColor) {
    case black:
      easyvr.setPinOutput(LED_GREEN, LOW);
      easyvr.setPinOutput(LED_RED, LOW);
      easyvr.setPinOutput(LED_BLUE, LOW);
      break;
    case white:
      easyvr.setPinOutput(LED_GREEN, HIGH);
      easyvr.setPinOutput(LED_RED, HIGH);
      easyvr.setPinOutput(LED_BLUE, HIGH);
      break;
    case red:
      easyvr.setPinOutput(LED_RED, HIGH);
      easyvr.setPinOutput(LED_GREEN, LOW);
      easyvr.setPinOutput(LED_BLUE, LOW);
      break;
    case green:
      easyvr.setPinOutput(LED_RED, LOW);
      easyvr.setPinOutput(LED_GREEN, HIGH);
      easyvr.setPinOutput(LED_BLUE, LOW);
      break;
    case blue:
      easyvr.setPinOutput(LED_RED, LOW);
      easyvr.setPinOutput(LED_GREEN, LOW);
      easyvr.setPinOutput(LED_BLUE, HIGH);
      break;
    case yellow:
      easyvr.setPinOutput(LED_RED, HIGH);
      easyvr.setPinOutput(LED_GREEN, HIGH);
      easyvr.setPinOutput(LED_BLUE, LOW);
      break;
    case purple:
      easyvr.setPinOutput(LED_RED, HIGH);
      easyvr.setPinOutput(LED_GREEN, LOW);
      easyvr.setPinOutput(LED_BLUE, HIGH);

      break;
  }
}

