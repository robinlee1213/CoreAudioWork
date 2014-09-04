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


@interface Recorder()

@property (nonatomic) MyRecorder *recorder;
@property (nonatomic) AudioQueueRef *queue;

@end



@implementation Recorder

- (instancetype)init {
    self = [super init];
    return self;
}

- (void)stop
{
    self.recorder->running = false;
    Check(AudioQueueStop(*self.queue, TRUE),"AudioQueueStop Failed");
}

- (void)start
{
    MyRecorder recorder = {0};
    self.recorder = &recorder;
    
    AudioStreamBasicDescription recordFormat;
    memset(&recordFormat, 0, sizeof(recordFormat));
    
    GetDefaultInputSampleRate(&recordFormat.mSampleRate);
    recordFormat.mFormatID = kAudioFormatMPEG4AAC;
    recordFormat.mChannelsPerFrame = 2;
    UInt32 propSize = sizeof(recordFormat);
    Check(AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &propSize,&recordFormat),
               "AudioFormatGetProperty Failed");
    
    
    AudioQueueRef queue = {0};
    self.queue = &queue;
    Check(AudioQueueNewInput(&recordFormat, InputCallback, &recorder, NULL, NULL, 0, &queue),
               "AudioQueueInput Failed");
    
    CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFSTR("/Users/Panthe/Desktop/fagget.caf"),kCFURLPOSIXPathStyle,true);
    Check(AudioFileCreateWithURL(url, kAudioFileCAFType, &recordFormat, kAudioFileFlags_EraseFile, &recorder.recordFile),
               "AudioFileCreateWithURL Failed");

    
    CFRelease(url);
    CopyCookieEncoderToFile(queue, recorder.recordFile);
    int bufferSize = GetOptimalBufferSize();
    int bufferIndex;
    
    
    for (bufferIndex = 0; bufferIndex < kNumberRecordBuffers; ++bufferIndex) {
        AudioQueueBufferRef buffer;
        Check(AudioQueueAllocateBuffer(queue, bufferSize, &buffer),
                   "AUdioQueueAllocate Failed");
        Check(AudioQueueEnqueueBuffer(queue, buffer, 0, NULL),
                   "AudioQueueEnqueue Failed");
    }
    
    recorder.running = true;
    Check(AudioQueueStart(*self.queue, NULL), "AudioqueueStartFailed");
    
    //Check(AudioQueueStop(*self.queue, TRUE),"AudioQUEUESTOPFAILED");

    
}

int GetOptimalBufferSize() {
    return 2046;
}

static void InputCallback(void *inUserData,
                          AudioQueueRef inQueue,
                          AudioQueueBufferRef inBuffer,
                          const AudioTimeStamp *inStartTime,
                          UInt32 inNumPacket,
                          const AudioStreamPacketDescription *inPacketDesc) {
    
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
    
}

void Check(OSStatus error, const char *operation)
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
