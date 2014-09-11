//
//  AppDelegate.m
//  CoreAudioWork
//
//  Created by Panthe on 9/4/14.
//  Copyright (c) 2014 panthesingh. All rights reserved.
//

#import "AppDelegate.h"
#import "Recorder.h"
#import "Player.h"
#import "AUPlayer.h"
#import "AUSpeech.h"
#import "AUSine.h"
#import "AUMixer.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *startButton;
@property (weak) IBOutlet NSButton *stopButton;

@property (nonatomic) Recorder *recorder;
@property (nonatomic) Player   *player;
@property (nonatomic) AUPlayer *auPlayer;
@property (nonatomic) AUSpeech *auSpeech;
@property (nonatomic) AUSine *auSine;
@property (nonatomic) AUMixer *auMixer;




@end

@implementation AppDelegate
            
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self.startButton setAction:@selector(start)];
    [self.startButton setTarget:self];
    [self.stopButton setAction:@selector(stop)];
    [self.stopButton setTarget:self];
    
    self.recorder = [Recorder new];
    self.player = [Player new];
    self.auPlayer = [AUPlayer new];
    self.auSpeech = [AUSpeech new];
    self.auSine = [AUSine new];
    self.auMixer = [AUMixer new];



    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)start
{
    [self.auMixer start];
}

- (void)stop
{
    [self.auMixer stop];
}

@end
