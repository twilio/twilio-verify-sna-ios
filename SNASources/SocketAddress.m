//
//  SocketAddress.m
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

// Original implementation: https://github.com/boku-inc/boku-wifi-ios

#import "SocketAddress.h"
#import <Foundation/Foundation.h>
#import <arpa/inet.h>
#import <netinet/in.h>
#import <sys/socket.h>

/**
 A wrapper class that makes it convenient to get relevant information, such as length/size, about a socket address structure. Most socket functions require information about socket address structures as an argument.
 */
@implementation SocketAddress
- (instancetype)initWithSockaddr:(struct sockaddr *)sockaddr {
	self = [super init];
	self.sockaddr = sockaddr;
	return self;
}

- (socklen_t)size {
	switch (self.sockaddr->sa_family) {
	case AF_INET:
		return sizeof(struct sockaddr_in);
	case AF_INET6:
		return sizeof(struct sockaddr_in6);
	default:
		return 0;
	}
}

- (NSString *)description {
	NSString *family;
	NSString *address;
	int bufferSize = MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN);
	char buffer[bufferSize];
	switch (self.sockaddr->sa_family) {
		case AF_INET:
			family = @"IPv4";
			address = [NSString stringWithUTF8String:inet_ntop(self.sockaddr->sa_family, &((struct sockaddr_in *)self.sockaddr)->sin_addr, buffer, bufferSize)];
			break;
		case AF_INET6:
			family = @"IPv6";
			address = [NSString stringWithUTF8String:inet_ntop(self.sockaddr->sa_family, &((struct sockaddr_in6 *)self.sockaddr)->sin6_addr, buffer, bufferSize)];
			break;
	}
	return [NSString stringWithFormat:@"%@ %@", family, address];
}
@end
