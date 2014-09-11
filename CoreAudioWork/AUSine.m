//
//  AUSine.m
//  CoreAudioWork
//
//  Created by Panthe on 9/7/14.
//  Copyright (c) 2014 panthesingh. All rights reserved.
//

#import "AUSine.h"
#import <AudioToolbox/AudioToolbox.h>

#define sineFrequency 800.0

typedef struct SineWave
{
    AudioUnit outputUnit;
    double startingFrameCount;
    
} SineWave;

@implementation AUSine {
    SineWave player;
}

- (void)stop
{
    AudioOutputUnitStop(player.outputUnit);
    AudioUnitUninitialize(player.outputUnit);
    AudioComponentInstanceDispose(player.outputUnit);
}

- (void)start
{
    CreateOuputUnit(&player);
    Check(AudioOutputUnitStart(player.outputUnit),"OutputUnitStartFailed");
}

static OSStatus SineWaveRenderProc(void *inRefCon,
                                AudioUnitRenderActionFlags *ioActionFlags,
                                const AudioTimeStamp *inTimeStamp,
                                UInt32 inBusNumber,
                                UInt32 inNumberFrames,
                                AudioBufferList *ioData)
{
    SineWave * player = (SineWave *)inRefCon;
    double j = player->startingFrameCount;
    double cycleLength = 44100 / sineFrequency;
    int frame = 0;
    for (frame = 0; frame < inNumberFrames; frame++) {
        Float32 *data = (Float32 *)ioData->mBuffers[0].mData;
        (data)[frame] = (Float32)sin (2 * M_PI * (j / cycleLength));
        data = (Float32*)ioData->mBuffers[1].mData;
        (data)[frame] = (Float32)sin (2 * M_PI * (j / cycleLength));
        j += 1.0;
        if (j > cycleLength) j -= cycleLength;
    }
    player->startingFrameCount = j;
    return noErr;
}

static void CreateOuputUnit(SineWave *player)
{
    AudioComponentDescription outputcd;
    outputcd.componentType = kAudioUnitType_Output;
    outputcd.componentSubType = kAudioUnitSubType_DefaultOutput;
    outputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    AudioComponent comp = AudioComponentFindNext(NULL, &outputcd);
    if (comp == NULL) {
        printf ("can't get output unit");
        exit (-1);
    }
    
    Check(AudioComponentInstanceNew(comp, &player->outputUnit), "Couldn't open component for outputUnit");
    
    AURenderCallbackStruct input;
    input.inputProc = SineWaveRenderProc;
    input.inputProcRefCon = &player;
    Check(AudioUnitSetProperty(player->outputUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, 0, &input, sizeof(input)), "AudioUnitSetPropertySineWaveFailed");
    AudioUnitInitialize(player->outputUnit);

    
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
