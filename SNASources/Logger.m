//
//  Logger.m
//  
//
//  Created by Alejandro Orozco Builes on 11/01/24.
//

#import <Foundation/Foundation.h>
#import "Logger.h"

@implementation Logger

// Array to store log entries during a session
static NSMutableArray<NSString *> *logs;

// Start a new session by clearing existing logs
+ (void)startNewSession {
    logs = [NSMutableArray array];
}

// Record a log entry with time, line, and message
+ (void)log:(NSString *)message lineNumber:(NSInteger)lineNumber {
    NSString *logEntry = [NSString stringWithFormat:@"%@ [Line %ld]: %@", [NSDate date], (long)lineNumber, message];
    [logs addObject:logEntry];
}

// Get all logs as a single string
+ (NSString *)getText {
    if(logs) {
        return [logs componentsJoinedByString:@"\n"];
    } else {
        return @"";
    }
}

@end
