//
//  Playback.m
//  CoreAudioWork
//
//  Created by Panthe on 9/5/14.
//  Copyright (c) 2014 panthesingh. All rights reserved.
//

#import "Player.h"
#import <AudioToolbox/AudioToolbox.h>

#define kPlayBackFile CFSTR("/Users/Panthe/Desktop/money.mp3")
#define kNumberPlaybackBuffers 3

typedef struct MyPlayer {
    AudioFileID                     playbackFile;
    SInt64                          packetPosition;
    UInt32                          numPacketsToRead;
    AudioStreamPacketDescription    *packetDescs;
    Boolean                         isDone;
    
} MyPlayer;


@implementation Player {
    
    MyPlayer player;
    AudioQueueRef queue;
}


- (void)start
{
    CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, kPlayBackFile, kCFURLPOSIXPathStyle, false);
    Check(AudioFileOpenURL(url, kAudioFileReadPermission, 0, &player.playbackFile),"AudioFileOpenFailed");
    CFRelease(url);
    
    AudioStreamBasicDescription dataFormat;
    UInt32 dataSize = sizeof(dataFormat);
    Check(AudioFileGetProperty(player.playbackFile, kAudioFilePropertyDataFormat, &dataSize, &dataFormat),
          "AudioFileGetPropertyFailed");
    
    Check(AudioQueueNewOutput(&dataFormat, OutputCallback, &player, NULL, NULL, 0, &queue),"AudioQueueNewOutputFailed");
    
    UInt32 bufferByteSize;
    CalculateBufferBytes(player.playbackFile, dataFormat, 0.5, &bufferByteSize, &player.numPacketsToRead);;
    
    bool isFormatVBR = (dataFormat.mBytesPerPacket == 0 || dataFormat.mFramesPerPacket == 0);
    if (isFormatVBR) player.packetDescs = (AudioStreamPacketDescription*) malloc(sizeof(AudioStreamPacketDescription) * player.numPacketsToRead);
    else player.packetDescs = NULL;
    
    CopyEncoderCookieToQueue(player.playbackFile, queue);
    
    AudioQueueBufferRef buffers[kNumberPlaybackBuffers]; player.isDone = false;
    player.packetPosition = 0;
    int i;
    for (i = 0; i < kNumberPlaybackBuffers; ++i) {
        Check(AudioQueueAllocateBuffer(queue, bufferByteSize,
                                            &buffers[i]), "AudioQueueAllocateBuffer failed");
        OutputCallback(&player, queue, buffers[i]);
        if (player.isDone) break;
    }
    
    Check(AudioQueueStart(queue, NULL), "AudioQueueStart failed");
}


static void OutputCallback(void *inUserData,
                           AudioQueueRef inAQ,
                           AudioQueueBufferRef inBuffer)
{
    MyPlayer *player = (MyPlayer *)inUserData;
    if (player->isDone) return;
    
    UInt32 numBytes;
    UInt32 nPackets = player->numPacketsToRead;
    Check(AudioFileReadPackets(player->playbackFile, false, &numBytes, player->packetDescs, player->packetPosition, &nPackets, inBuffer->mAudioData),
          "AudioFileReadPackets failed");
    
    if (nPackets > 0) {
        inBuffer->mAudioDataByteSize = numBytes;
        AudioQueueEnqueueBuffer(inAQ, inBuffer, (player->packetDescs ? nPackets : 0), player->packetDescs);
        player->packetPosition += nPackets;
    } else {
        Check(AudioQueueStop(inAQ, false),"AudioQueueStop failed"); player->isDone = true;
    }
}

static void CalculateBufferBytes(AudioFileID file, AudioStreamBasicDescription desc, float seconds, UInt32 *outBufferSize, UInt32 *outNumPackets)
{
    UInt32 maxPacketSize;
    UInt32 propSize = sizeof(maxPacketSize);
    
    Check(AudioFileGetProperty(file, kAudioFilePropertyPacketSizeUpperBound, &propSize, &maxPacketSize),
          "AudioFilePacketSIezeFailed");
    
    
    static const int maxBufferSize = 0x10000;
    static const int minBufferSize = 0x4000;
    
    if (desc.mFramesPerPacket) {
        Float64 numPacketsForTime = desc.mSampleRate / desc.mFramesPerPacket * seconds;
        *outBufferSize = numPacketsForTime * maxPacketSize;
    } else {
        *outBufferSize = maxBufferSize > maxPacketSize ? maxBufferSize : maxPacketSize;
        if (*outBufferSize > maxBufferSize && *outBufferSize > maxPacketSize) *outBufferSize = maxBufferSize;
    }
    
    if (*outBufferSize > maxBufferSize && *outBufferSize > maxPacketSize) *outBufferSize = maxBufferSize;
    else {
        if (*outBufferSize < minBufferSize) *outBufferSize = minBufferSize;
    }
    *outNumPackets = *outBufferSize / maxPacketSize;
}

static void CopyEncoderCookieToQueue(AudioFileID file, AudioQueueRef queue)
{
    UInt32 propertySize;
    OSStatus result = AudioFileGetPropertyInfo(file, kAudioFilePropertyMagicCookieData, &propertySize, NULL);
    if (result == noErr && propertySize > 0) {
        Byte* magicCookie = (UInt8*)malloc(sizeof(UInt8) * propertySize);
        Check(AudioFileGetProperty (file, kAudioFilePropertyMagicCookieData, &propertySize, magicCookie),"Get cookie from file failed");
        Check(AudioQueueSetProperty(queue, kAudioQueueProperty_MagicCookie, magicCookie, propertySize), "Set cookie on queue failed");
        free(magicCookie);
    }
}


- (void)stop
{
    player.isDone = true;
    Check(AudioQueueStop(queue, TRUE), "AudioQueueStop failed");
    AudioQueueDispose(queue, TRUE);
    AudioFileClose(player.playbackFile);
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
