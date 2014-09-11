//
//  AUSpeech.m
//  CoreAudioWork
//
//  Created by Panthe on 9/7/14.
//  Copyright (c) 2014 panthesingh. All rights reserved.
//

#import "AUSpeech.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>

typedef struct SpeechAUGraph
{
    AUGraph graph;
    AudioUnit speechAU;
    
} SpeechAUGraph;

@implementation AUSpeech {
    SpeechAUGraph player;
}

- (void)stop
{
    AUGraphStop (player.graph);
    AUGraphUninitialize (player.graph);
    AUGraphClose(player.graph);
}

- (void)start
{
    CreateAUGraph(&player);
    PrepareSpeech(&player);
    Check(AUGraphStart(player.graph), "AUGraphStart failed");
}

static void CreateAUGraph(SpeechAUGraph *player)
{
    Check(NewAUGraph(&player->graph),"NEW AU GRAPH FAILED");
    
    AudioComponentDescription outputcd;
    outputcd.componentType = kAudioUnitType_Output;
    outputcd.componentSubType = kAudioUnitSubType_DefaultOutput;
    outputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    AUNode outputNode;
    Check(AUGraphAddNode(player->graph, &outputcd, &outputNode),"AUGraphNodeADDNODE failed");
    
    AudioComponentDescription speechcd;
    speechcd.componentType = kAudioUnitType_Generator;
    speechcd.componentSubType = kAudioUnitSubType_SpeechSynthesis;
    speechcd.componentManufacturer = kAudioUnitManufacturer_Apple;

    AUNode speechNode;
    Check(AUGraphAddNode(player->graph, &speechcd, &speechNode),"ADDSPEECHNODE FAILED");
    
    Check(AUGraphOpen(player->graph), "AUGRAPH open FAILED");
    Check(AUGraphNodeInfo(player->graph, speechNode, NULL, &player->speechAU),"AUgraphInfoAUnitFailed");
    Check(AUGraphConnectNodeInput(player->graph, speechNode, 0, outputNode, 0),"AUgraphConnectFailed");
    Check(AUGraphInitialize(player->graph), "GraphInitializefailed");
}

static void PrepareSpeech(SpeechAUGraph *player)
{
    SpeechChannel channel;
    UInt32 propsize = sizeof(SpeechChannel);
    Check(AudioUnitGetProperty(player->speechAU, kAudioUnitProperty_SpeechChannel, kAudioUnitScope_Global, 0, &channel, &propsize),"AUdioUnitGetSPeechFailed");
    SpeakCFString(channel, CFSTR("Hello World"), NULL);
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
