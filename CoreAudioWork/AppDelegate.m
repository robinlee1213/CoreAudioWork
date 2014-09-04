//
//  AppDelegate.m
//  CoreAudioWork
//
//  Created by Panthe on 9/4/14.
//  Copyright (c) 2014 panthesingh. All rights reserved.
//

#import "AppDelegate.h"
#import "Recorder.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *startButton;
@property (weak) IBOutlet NSButton *stopButton;

@property (nonatomic) Recorder *recorder;

@end

@implementation AppDelegate
            
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self.startButton setAction:@selector(start)];
    [self.startButton setTarget:self];
    [self.stopButton setAction:@selector(stop)];
    [self.stopButton setTarget:self];
    
    self.recorder = [Recorder new];
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)start
{
    [self.recorder start];
}

- (void)stop
{
    [self.recorder stop];
}

@end
