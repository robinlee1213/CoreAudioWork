//
//  Recorder.m
//  CoreAudio
//
//  Created by Singh on 9/3/14.
//  Copyright (c) 2014 panthesingh. All rights reserved.
//

#import "Recorder.h"
#import <AudioToolbox/AudioToolbox.h>
#define kNumberRecordBuffers 3


typedef struct MyRecorder {
    AudioFileID     recordFile;
    SInt64          recordPacket;
    Boolean         running;
} MyRecorder;

@implementation Recorder {
    AudioQueueRef queue;
    MyRecorder recorder;
}

- (instancetype)init {
    self = [super init];
    return self;
}

- (void)stop
{
    recorder.running = false;
    Check(AudioQueueStop(queue, true),"AudioQueueStop Failed");
    AudioQueueDispose(queue, TRUE);
    AudioFileClose(recorder.recordFile);
}

- (void)start
{
    AudioStreamBasicDescription recordFormat;
    memset(&recordFormat, 0, sizeof(recordFormat));
    
    GetDefaultInputSampleRate(&recordFormat.mSampleRate);
    recordFormat.mFormatID = kAudioFormatMPEG4AAC;
    recordFormat.mChannelsPerFrame = 2;
    UInt32 propSize = sizeof(recordFormat);
    Check(AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &propSize, &recordFormat),
               "AudioFormatGetProperty Failed");
    Check(AudioQueueNewInput(&recordFormat, InputCallback, &recorder, NULL, NULL, 0, &queue),
               "AudioQueueInput Failed");
    CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFSTR("/Users/Panthe/Desktop/fagget.caf"),kCFURLPOSIXPathStyle,true);
    Check(AudioFileCreateWithURL(url, kAudioFileCAFType, &recordFormat, kAudioFileFlags_EraseFile, &recorder.recordFile),
               "AudioFileCreateWithURL Failed");
    CFRelease(url);
    CopyCookieEncoderToFile(queue, recorder.recordFile);
    
    int bufferSize = GetOptimalBufferSize(&recordFormat, queue, 0.5);
    int bufferIndex;
    for (bufferIndex = 0; bufferIndex < kNumberRecordBuffers; ++bufferIndex) {
        AudioQueueBufferRef buffer;
        Check(AudioQueueAllocateBuffer(queue, bufferSize, &buffer),
                   "AUdioQueueAllocate Failed");
        Check(AudioQueueEnqueueBuffer(queue, buffer, 0, NULL),
                   "AudioQueueEnqueue Failed");
    }
    
    recorder.running = true;
    Check(AudioQueueStart(queue, NULL), "AudioqueueStartFailed");
}

static void InputCallback(void *inUserData,
                          AudioQueueRef inAQ,
                          AudioQueueBufferRef inBuffer,
                          const AudioTimeStamp *inStartTime,
                          UInt32 inNumberPacketDescriptions,
                          const AudioStreamPacketDescription *inPacketDescs )
{
    MyRecorder *myRecorder = (MyRecorder *)inUserData;
    
    if (inNumberPacketDescriptions > 0) {
    Check(AudioFileWritePackets(myRecorder->recordFile, false, inBuffer->mAudioDataByteSize, inPacketDescs, myRecorder->recordPacket, &inNumberPacketDescriptions, inBuffer->mAudioData),
          "AudioWRITEFailedbruh");
        myRecorder->recordPacket += inNumberPacketDescriptions;
    }
    
    if (myRecorder->running) Check(AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL),
                                   "AudioQueueEnqueueBuffer failed");
    
}

int GetOptimalBufferSize(const AudioStreamBasicDescription *format, AudioQueueRef queue, float seconds) {
    
    int packets, frames, bytes;
    frames = (int)ceil(seconds * format->mSampleRate);
    
    if (format->mBytesPerFrame > 0) bytes = frames * format->mBytesPerFrame;
    else {
        UInt32 maxPacketSize;
        if (format->mBytesPerPacket > 0) maxPacketSize = format->mBytesPerPacket;
        else {
            UInt32 propertySize = sizeof(maxPacketSize);
            Check(AudioQueueGetProperty(queue, kAudioConverterPropertyMaximumOutputPacketSize, &maxPacketSize, &propertySize),
                       "AudioQueueGetPropertyPacketSize Failed");
        }
        if (format->mFramesPerPacket > 0) packets = frames / format->mFramesPerPacket;
        else packets = frames;
        if (packets == 0) packets = 1;
        bytes = packets * maxPacketSize;
    }
    return bytes;
}


OSStatus GetDefaultInputSampleRate(Float64 *outSampleRate) {
    
    OSStatus error;
    AudioDeviceID deviceID = 0;
    
    AudioObjectPropertyAddress propertyAddress;
    UInt32 propertySize;
    propertyAddress.mSelector = kAudioHardwarePropertyDefaultInputDevice;
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress.mElement = 0;
    propertySize = sizeof(AudioDeviceID);
    error = AudioHardwareServiceGetPropertyData(kAudioObjectSystemObject,
                                                &propertyAddress,
                                                0,
                                                NULL,
                                                &propertySize,
                                                &deviceID);
    
    if (error) return error;
    
    propertyAddress.mSelector = kAudioDevicePropertyNominalSampleRate;
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress.mElement = 0;
    propertySize = sizeof(Float64);
    
    error = AudioHardwareServiceGetPropertyData(deviceID,
                                                &propertyAddress,
                                                0,
                                                NULL,
                                                &propertySize,
                                                outSampleRate);
    
    return error;
    
}

void CopyCookieEncoderToFile(AudioQueueRef queue, AudioFileID audioFile)
{
    OSStatus error;
    UInt32 propertySize;
    error = AudioQueueGetPropertySize(queue, kAudioConverterCompressionMagicCookie, &propertySize);
    if (error == noErr && propertySize > 0) {
        Byte *magicCookie = (Byte *)malloc(propertySize);
        Check(AudioQueueGetProperty(queue, kAudioQueueProperty_MagicCookie, magicCookie, &propertySize),
                   "AudioQueueGetPropertyMagicCookie Failed");
        Check(AudioFileSetProperty(audioFile, kAudioFilePropertyMagicCookieData, propertySize, magicCookie),
              "AudioFileSetPropertyMagicCookie Failed");
        free(magicCookie);
    }
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
