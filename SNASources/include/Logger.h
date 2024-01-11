//
//  Header.h
//  
//
//  Created by Alejandro Orozco Builes on 11/01/24.
//

#import <Foundation/Foundation.h>

@interface Logger : NSObject

// Start a new session by clearing existing logs
+ (void)startNewSession;

// Record a log entry with time, line, and message
+ (void)log:(NSString *)message lineNumber:(NSInteger)lineNumber;

// Get all logs as a single string
+ (NSString *)getText;

@end
