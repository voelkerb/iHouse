//
//  Constants.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 08/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "Constants.h"

NSString * const IRToggleAction = @"toggle:";
NSString * const ToggleCommand = @"ToggleCommand";
NSString * const IRToggleCommand = @"IRToggleCommand";
NSString * const SyncCommand = @"SyncCommand";
NSString * const NCSyncComplete = @"NCSyncComplete";
NSString * const NCNewDeviceImage = @"NCNewDeviceImage";
NSString * const NCNewRoomImage = @"NCNewRoomImage";
NSString * const NCNewGroupImage = @"NCNewGroupImage";
NSString * const NCNewDeviceInfoImage = @"NCNewDeviceInfoImage";
NSString * const KeyCommand = @"KeyCommand";
NSString * const KeyDevices = @"KeyDevices";
NSString * const KeyDevice = @"KeyDevice";
NSString * const KeyDeviceInfo = @"KeyDeviceInfo";
NSString * const KeyData = @"KeyData";
NSString * const KeyRooms = @"KeyRooms";
NSString * const KeyRoom = @"KeyRoom";
NSString * const KeyName = @"KeyName";
NSString * const KeyImage = @"KeyImage";
NSString * const KeyType = @"KeyType";
NSString * const KeyInfo = @"KeyInfo";
NSString * const KeyIRCommands = @"KeyIRCommands";
NSString * const KeyIndex = @"KeyIndex";
NSString * const KeyGroups = @"KeyGroups";
NSString * const KeyGroup = @"KeyGroup";

NSString * const StartAutoSync = @"StartAutoSync";
NSString * const SyncFinished = @"SyncFinished";



NSString * const SiriCommand = @"siri:";
NSString * const SwitchCommand = @"switch";

// Coming from server
NSString * const SyncKeyType = @"type";
NSString * const SyncKeyRoom = @"room";
NSString * const SyncKeyName = @"name";
NSString * const SyncKeyImage = @"image";
NSString * const SyncKeyInfo = @"info";
int const SyncKeyRoomType = 1000;
int const SyncKeyGroupType = 1001;

#define COMMAND_UPDATE_DEVICE @"up:"
#define COMMAND_ACTION_DEVICE @"action:"
#define COMMAND_ACTION_GROUP @"group:"
#define COMMAND_SEPERATOR @";/;"



// Device changed notification
NSString * const DeviceDidChange = @"DeviceDidChange";

// State key for dictionary
NSString * const SocketLightKeyState = @"SocketLightKeyState";

// State key for dictionary
NSString * const HeatingKeyTemp = @"HeatingKeyTemp";

// IR key for dictionary
NSString * const IRKeyCommands = @"IRKeyCommands";

// Voltage key for dictionary
NSString * const MeterKeyVoltage = @"MeterKeyVoltage";
// Current key for dictionary
NSString * const MeterKeyCurrent = @"MeterKeyCurrent";
// Power key for dictionary
NSString * const MeterKeyPower = @"MeterKeyPower";
// Enegery key for dictionary
NSString * const MeterKeyEnergy = @"MeterKeyEnergy";
// TimeStamp key for dictionary
NSString * const MeterKeyTimeStamp = @"MeterKeyTimeStamp";

// Movement key for dictionary
NSString * const SensorKeyMovement = @"SensorKeyMovement";
// Humidity key for dictionary
NSString * const SensorKeyHumidity = @"SensorKeyHumidity";
// Temperature key for dictionary
NSString * const SensorKeyTemperature = @"SensorKeyTemperature";
// Pressure key for dictionary
NSString * const SensorKeyPressure = @"SensorKeyPressure";
// Brightnes key for dictionary
NSString * const SensorKeyBrightness = @"SensorKeyBrightness";
// TimeStamp key for dictionary
NSString * const SensorKeyTimeStamp = @"SensorKeyTimeStamp";





@implementation Constants

@end
