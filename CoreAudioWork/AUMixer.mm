//
//  AUMixing.m
//  CoreAudioWork
//
//  Created by Panthe on 9/7/14.
//  Copyright (c) 2014 panthesingh. All rights reserved.
//

#import "AUMixer.h"
#import "CARingBuffer.h"
#import <AudioToolbox/AudioToolbox.h>

typedef struct AUGraphPlayer
{
    AudioStreamBasicDescription streamFormat;
    AUGraph graph;

    AudioUnit inputUnit;
    AudioUnit outputUnit;
    
    AudioBufferList *inputBuffer;
    CARingBuffer *ringBuffer;
    
    Float64 firstInputSample;
    Float64 firstOutputSample;
    Float64 inToOutSampleOffset;

    
} AUGraphPlayer;

@implementation AUMixer
{
    AUGraphPlayer player;
}

- (void)start
{
    createInputUnit(&player);
    createAUGraph(&player);
    
    Check(AudioOutputUnitStart(player.inputUnit), "AudioOutputUnitStart failed");
    Check(AUGraphStart(player.graph), "AUGraphStart failed");
}

- (void)stop
{
    AUGraphStop (player.graph);
    AUGraphUninitialize (player.graph);
    AUGraphClose(player.graph);
}

static  void createInputUnit(AUGraphPlayer *player)
{
    AudioComponentDescription inputcd;
    inputcd.componentType = kAudioUnitType_Output;
    inputcd.componentSubType = kAudioUnitSubType_HALOutput;
    inputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
    AudioComponent comp = AudioComponentFindNext(NULL, &inputcd);
    if (comp == NULL) {
        printf ("Can't get output unit");
        exit (-1); }
    Check(AudioComponentInstanceNew(comp, &player->inputUnit), "Couldn't open component for inputUnit");
    
    UInt32 disableFlag = 0;
    UInt32 enableFlag = 1;
    AudioUnitScope outputBus = 0;
    AudioUnitScope inputBus = 1;
    Check(AudioUnitSetProperty(player->inputUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, inputBus, &enableFlag, sizeof(enableFlag)),"AUDIOUNITSETPROPFAILED");
    Check(AudioUnitSetProperty(player->inputUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, outputBus, &disableFlag, sizeof(enableFlag)),"audiounitsetpropfailed");
    
    AudioDeviceID defaultDevice = kAudioObjectUnknown;
    UInt32 propertySize = sizeof (defaultDevice);
    AudioObjectPropertyAddress defaultDeviceProperty;
    defaultDeviceProperty.mSelector = kAudioHardwarePropertyDefaultInputDevice;
    defaultDeviceProperty.mScope = kAudioObjectPropertyScopeGlobal;
    defaultDeviceProperty.mElement = kAudioObjectPropertyElementMaster;
    Check(AudioObjectGetPropertyData(kAudioObjectSystemObject, &defaultDeviceProperty, 0, NULL, &propertySize, &defaultDevice), "Couldn't get default input device");
    Check(AudioUnitSetProperty(player->inputUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, outputBus, &defaultDevice, sizeof(defaultDevice)), "Couldn't set default device on I/O unit");
    propertySize = sizeof (AudioStreamBasicDescription);
    Check(AudioUnitGetProperty(player->inputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output,inputBus, &player->streamFormat, &propertySize), "Couldn't get ASBD from input unit");
    AudioStreamBasicDescription deviceFormat;
    Check(AudioUnitGetProperty(player->inputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, inputBus, &deviceFormat, &propertySize), "Couldn't get ASBD from input unit");
    player->streamFormat.mSampleRate = deviceFormat.mSampleRate;
    
    propertySize = sizeof (AudioStreamBasicDescription);
    Check(AudioUnitSetProperty(player->inputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, inputBus, &player->streamFormat, propertySize), "Couldn't set ASBD on input unit");
    
    UInt32 bufferSizeFrames = 0;
    propertySize = sizeof(UInt32);
    Check(AudioUnitGetProperty(player->inputUnit,kAudioDevicePropertyBufferFrameSize, kAudioUnitScope_Global,0, &bufferSizeFrames, &propertySize), "Couldn't get buffer?");
    UInt32 bufferSizeBytes = bufferSizeFrames * sizeof(Float32);
    UInt32 propsize = offsetof(AudioBufferList, mBuffers[0]) + (sizeof(AudioBuffer) * player->streamFormat.mChannelsPerFrame);
    
    player->inputBuffer = (AudioBufferList *)malloc(propsize);
    player->inputBuffer->mNumberBuffers = player->streamFormat.mChannelsPerFrame;
    // Pre-malloc buffers for AudioBufferLists
    for(UInt32 i =0; i< player->inputBuffer->mNumberBuffers ; i++) {
        player->inputBuffer->mBuffers[i].mNumberChannels = 1;
        player->inputBuffer->mBuffers[i].mDataByteSize = bufferSizeBytes;
        player->inputBuffer->mBuffers[i].mData = malloc(bufferSizeBytes);
    }
    
    player->ringBuffer = new CARingBuffer();
    
    player->ringBuffer->Allocate(player->streamFormat.mChannelsPerFrame, player->streamFormat.mBytesPerFrame, bufferSizeFrames * 3);
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = InputRenderProc;
    callbackStruct.inputProcRefCon = player;
    Check(AudioUnitSetProperty(player->inputUnit, kAudioOutputUnitProperty_SetInputCallback,
                                    kAudioUnitScope_Global, 0,
                                    &callbackStruct, sizeof(callbackStruct)),
               "Couldn't set input callback");
    
    Check(AudioUnitInitialize(player->inputUnit), "Couldn't initialize input unit");
    player->firstInputSampleTime = -1;
    player->inToOutSampleTimeOffset = -1;
    printf ("Bottom of CreateInputUnit()\n");
}

static  void createAUGraph(AUGraphPlayer *player)
{
    
}

static OSStatus InputRenderProc()
{
    
}

static void Check(OSStatus error, const char *operation)
{
    if (error == noErr) return;
    char errorString[20];
    if (isprint(errorString[1]) && isprint(errorString[2]) &&
        isprint(errorString[3]) && isprint(errorString[4])) {
        
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else sprintf(errorString, "%d", (int)error);
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
    exit(1);
}

@end
