// Original implementation and credits to BENJAMIN BRYANT BUDIMAN: https://github.com/boku-inc/boku-wifi-ios
//
//  SocketAddress.h
//  TwilioVerifySNA
//
//  Copyright © 2022 Twilio.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#ifndef SocketAddress_h
#define SocketAddress_h

#import <Foundation/Foundation.h>

typedef struct sockaddr *sockaddr_t;

@interface SocketAddress : NSObject
@property sockaddr_t sockaddr;
@property(readonly) socklen_t size;

- (instancetype)initWithSockaddr:(struct sockaddr *)address;
@end

#endif /* SocketAddress_h */
