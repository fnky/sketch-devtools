//
//  SDTFileWatcher.m
//  SketchConsole
//
//  Created by Andrey on 13/09/14.
//  Copyright (c) 2014 Turbobabr. All rights reserved.
//

#import "SDTFileWatcher.h"

@interface SDTFileWatcher (Private)
- (void)setupEventStreamRef;
@end

@implementation SDTFileWatcher

+ (id) fileWatcherWithPath:(NSString*)filePath delegate:(id)delegate {
    
    SDTFileWatcher *fw = [self new];
    fw.paths=@[filePath];
    fw.delegate = delegate;
    [fw setupEventStreamRef];
    
    return fw;
}


+ (id) fileWatcherWithPaths:(NSArray*)paths delegate:(id)delegate {
    SDTFileWatcher *fw = [self new];
    
    fw.paths=paths;
    fw.delegate = delegate;
    [fw setupEventStreamRef];
    
    return fw;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (streamRef) {
        FSEventStreamStop(streamRef);
        FSEventStreamInvalidate(streamRef);
        FSEventStreamRelease(streamRef);
    }
    
}


static void fsevents_callback(FSEventStreamRef streamRef, SDTFileWatcher *fw, int numEvents, const char *const eventPaths[], const FSEventStreamEventFlags *eventMasks, const uint64_t *eventIDs)
{
    
    id delegate = [fw delegate];
    
    if (delegate && [delegate respondsToSelector:@selector(fileWatcherDidRecieveFSEvent:)]) {
        [delegate fileWatcherDidRecieveFSEvent:fw];
    }
    
}

- (void)setupEventStreamRef {
    
    CFAbsoluteTime latency = 1.0;
    
    FSEventStreamContext  context = {0, (__bridge void *)self, NULL, NULL, NULL};
    NSArray* pathsToWatch = self.paths;
    streamRef = FSEventStreamCreate(kCFAllocatorDefault,
                                    (FSEventStreamCallback)&fsevents_callback,
                                    &context,
                                    (CFArrayRef)CFBridgingRetain(pathsToWatch),
                                    kFSEventStreamEventIdSinceNow,
                                    latency,
                                    kFSEventStreamCreateFlagWatchRoot);
    
    FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    
    FSEventStreamStart(streamRef);
    
}

@end
