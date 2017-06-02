//
//  Constants.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 08/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const IRToggleAction;
extern NSString * const ToggleCommand;
extern NSString * const IRToggleCommand;
extern NSString * const SyncCommand;
extern NSString * const NCSyncComplete;
extern NSString * const NCNewDeviceImage;
extern NSString * const NCNewRoomImage;
extern NSString * const NCNewGroupImage;
extern NSString * const NCNewDeviceInfoImage;
extern NSString * const KeyCommand;
extern NSString * const KeyDevices;
extern NSString * const KeyDevice;
extern NSString * const KeyDeviceInfo;
extern NSString * const KeyData;
extern NSString * const KeyRooms;
extern NSString * const KeyRoom;
extern NSString * const KeyName;
extern NSString * const KeyImage;
extern NSString * const KeyType;
extern NSString * const KeyInfo;
extern NSString * const KeyIRCommands;
extern NSString * const KeyIndex;
extern NSString * const KeyGroups;
extern NSString * const KeyGroup;

extern NSString * const StartAutoSync;
extern NSString * const SyncFinished;


extern NSString * const SiriCommand;
extern NSString * const SwitchCommand;


// Coming from server
extern NSString * const SyncKeyType;
extern NSString * const SyncKeyRoom;
extern NSString * const SyncKeyName;
extern NSString * const SyncKeyImage;
extern NSString * const SyncKeyInfo;
extern int const SyncKeyRoomType;
extern int const SyncKeyGroupType;



extern NSString * const DeviceDidChange;

// State key for dictionary
extern NSString * const SocketLightKeyState;

// State key for dictionary
extern NSString * const HeatingKeyTemp;

extern NSString * const IRKeyCommands;

// Voltage key for dictionary
extern NSString * const MeterKeyVoltage;
// Current key for dictionary
extern NSString * const MeterKeyCurrent;
// Power key for dictionary
extern NSString * const MeterKeyPower;
// Enegery key for dictionary
extern NSString * const MeterKeyEnergy;
// TimeStamp key for dictionary
extern NSString * const MeterKeyTimeStamp;

// Movement key for dictionary
extern NSString * const SensorKeyMovement;
// Humidity key for dictionary
extern NSString * const SensorKeyHumidity;
// Temperature key for dictionary
extern NSString * const SensorKeyTemperature;
// Pressure key for dictionary
extern NSString * const SensorKeyPressure;
// Brightnes key for dictionary
extern NSString * const SensorKeyBrightness;
// TimeStamp key for dictionary
extern NSString * const SensorKeyTimeStamp;




@interface Constants : NSObject

@end
