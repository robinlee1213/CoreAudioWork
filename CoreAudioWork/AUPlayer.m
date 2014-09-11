//
//  AudioUnits.m
//  CoreAudioWork
//
//  Created by Panthe on 9/5/14.
//  Copyright (c) 2014 panthesingh. All rights reserved.
//
#import "AUPlayer.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>


#define kPlayBackFile CFSTR("/Users/Panthe/Desktop/money.mp3")


typedef struct GraphPlayer
{
    AudioStreamBasicDescription     inputFormat;
    AudioFileID                     inputFile;
    AUGraph                         graph;
    AudioUnit                       fileAU;
    
} GraphPlayer;

@implementation AUPlayer {
    GraphPlayer player;
}

- (void)stop
{
    AUGraphStop (player.graph);
    AUGraphUninitialize (player.graph);
    AUGraphClose(player.graph);
    AudioFileClose(player.inputFile);
}

- (void)start
{
    CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, kPlayBackFile, kCFURLPOSIXPathStyle, false);
    Check(AudioFileOpenURL(url, kAudioFileReadPermission, 0, &player.inputFile),"AudioFileOpenFailed");
    CFRelease(url);
    
    UInt32 propSize = sizeof(player.inputFormat);
    Check(AudioFileGetProperty(player.inputFile, kAudioFilePropertyDataFormat, &propSize, &player.inputFormat), "AudioFileGetProperty");
    
    CreateAUGraph(&player);
    Float64 fileDuration = PrepareFileAU(&player);
    Check(AUGraphStart(player.graph), "AUGraphStartFailed");
    
}
static void CreateAUGraph(GraphPlayer *player)
{
    Check(NewAUGraph(&player->graph), "CreateAUGraphFailed");
    AudioComponentDescription outputcd;

    outputcd.componentType = kAudioUnitType_Output;
    outputcd.componentSubType = kAudioUnitSubType_DefaultOutput;
    outputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    AUNode outputNode;
    Check(AUGraphAddNode(player->graph, &outputcd, &outputNode), "AUGraphAddOutputNodeFailed");
    
    AudioComponentDescription fileplayercd;
    fileplayercd.componentType = kAudioUnitType_Generator;
    fileplayercd.componentSubType = kAudioUnitSubType_AudioFilePlayer;
    fileplayercd.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    AUNode fileNode;
    Check(AUGraphAddNode(player->graph, &fileplayercd, &fileNode), "AUGraphaddFileNodeFailed");
    Check(AUGraphOpen(player->graph),"AUGraphOpenFailed");
    Check(AUGraphNodeInfo(player->graph, fileNode, NULL, &player->fileAU),"AUGraphNodeInfoFailed");
    Check(AUGraphConnectNodeInput(player->graph, fileNode, 0, outputNode, 0), "AUGraphNodeConnectFailed");
    Check(AUGraphInitialize(player->graph),"AUGraphInitializeFailed");
    
}

static Float64 PrepareFileAU(GraphPlayer *player)
{
    Check(AudioUnitSetProperty(player->fileAU, kAudioUnitProperty_ScheduledFileIDs, kAudioUnitScope_Global, 0, &player->inputFile, sizeof(player->inputFile)), "AudioUnitSetPropertyFailed");
    
    UInt64 nPackets;
    UInt32 propSize = sizeof(nPackets);
    Check(AudioFileGetProperty(player->inputFile, kAudioFilePropertyAudioDataPacketCount, &propSize, &nPackets), "AudioUnitFileGetPropertFailed");
    
    ScheduledAudioFileRegion rgn;
    memset(&rgn.mTimeStamp, 0, sizeof(rgn.mTimeStamp));
    rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    rgn.mTimeStamp.mSampleTime = 0;
    rgn.mCompletionProc = NULL;
    rgn.mCompletionProcUserData = NULL;
    rgn.mAudioFile = player->inputFile;
    rgn.mLoopCount = 1;
    rgn.mStartFrame = 0;
    rgn.mFramesToPlay = (UInt32)nPackets * player->inputFormat.mFramesPerPacket;
    Check(AudioUnitSetProperty(player->fileAU, kAudioUnitProperty_ScheduledFileRegion, kAudioUnitScope_Global, 0, &rgn, sizeof(rgn)), "AUdioUNitSetPropertyFileRegionFailed");
    
    AudioTimeStamp startTime;
    memset(&startTime, 0, sizeof(startTime));
    startTime.mFlags = kAudioTimeStampHostTimeValid;
    startTime.mSampleTime = -1;
    Check(AudioUnitSetProperty(player->fileAU, kAudioUnitProperty_ScheduleStartTimeStamp, kAudioUnitScope_Global, 0, &startTime, sizeof(startTime)),"AudioUnitSetPropertyStartTimeFailed");
    return (nPackets * player->inputFormat.mFramesPerPacket) / player->inputFormat.mSampleRate;
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



