//
//  CellularSession.m
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

#import "CellularSession.h"
#import "SocketAddress.h"
#import "sslfuncs.h"
#import <Foundation/Foundation.h>
#import <ifaddrs.h>
#import <net/if.h>
#import <netdb.h>
#include <arpa/inet.h>
#import "CellularGetAddrinfo.h"

@implementation CellularSession

/**
 Requests a URL using the local system's cellular data.
 There are five important steps in this function:
    1). Find the address of the network interface for the local system's cellular data
    2). Find the address of the URL requested
    3). Bind and connect a socket to the addresses obtained from steps 1) and 2)
    4). Invoke the HTTP request using the instantiated socket from step 3)
    5). Parse the HTTP response and check whether it contains a redirect HTTP code. If the HTTP response contains a HTTP redirect code, obtain the redirect URL (which is found from the Location header), and return a string containing the redirect URL. E.g. "REDIRECT:https://redirect-url.com"
 These steps are labeled in the code below.
 
 @param url The URL to be requested
 @return A string response from the request to the URL
 */
- (CellularSessionResult * _Nonnull)performRequest:(NSURL * _Nonnull)url {
    // Prepare a class to return results.
    CellularSessionResult *sessionResult = [[CellularSessionResult alloc] init];
    sessionResult.result = nil;
    sessionResult.status = CellularSessionUnexpectedError;

    // Stores any errors that occur during execution
    __block OSStatus status;

    // All local (cellular interface) IP addresses of this device.
    NSMutableArray<SocketAddress *> *localAddresses = [NSMutableArray array];
    // All remote IP addresses that we're trying to connect to.
    NSMutableArray<SocketAddress *> *remoteAddresses = [NSMutableArray array];
    
    // The local (cellular interface) IP address of this device.
    SocketAddress *localAddress;
    // The remote IP address that we're trying to connect to.
    SocketAddress *remoteAddress;
    
    NSPredicate *ipv4Predicate = [NSPredicate predicateWithBlock:^BOOL(SocketAddress *evaluatedObject, NSDictionary<NSString *, id> *bindings) {
        return evaluatedObject.sockaddr->sa_family == AF_INET;
    }];
    NSPredicate *ipv6Predicate = [NSPredicate predicateWithBlock:^BOOL(SocketAddress *evaluatedObject, NSDictionary<NSString *, id> *bindings) {
        return evaluatedObject.sockaddr->sa_family == AF_INET6;
    }];
    
    struct ifaddrs *ifaddrPointer;
    struct ifaddrs *ifaddrs;
    
    // The getifaddrs() function creates a linked list of structures describing the network interfaces of the local system,
    // and stores the address of the first item of the list in *ifaddrPointer.
    // A zero return value for getaddrinfo() indicates successful completion; a non-zero return value indicates failure.
    // For more information, go to https://man7.org/linux/man-pages/man3/getifaddrs.3.html
    status = getifaddrs(&ifaddrPointer);
    if (status) {
        printf("Error occurred, cannot obtain network interfaces of the local system");
        sessionResult.status = CellularSessionCannotObtainNetworkInterfaces;
        return sessionResult;
    }
    
    // Step 1). Find the address of the network interface for the local system's cellular data
    
    ifaddrs = ifaddrPointer;
    while (ifaddrs) {
        // If the interface is up
        if (ifaddrs->ifa_flags & IFF_UP) {
            // If the interface is the pdp_ip0 (cellular data) interface
            if (strcmp(ifaddrs->ifa_name, "pdp_ip0") == 0) {
                switch (ifaddrs->ifa_addr->sa_family) {
                    case AF_INET:  // IPv4
                    case AF_INET6: // IPv6
                        [localAddresses addObject:[[SocketAddress alloc] initWithSockaddr:ifaddrs->ifa_addr]];
                        break;
                }
            }
        }
        ifaddrs = ifaddrs->ifa_next;
    }
    
    __block struct addrinfo *addrinfoPointer;
    struct addrinfo *addrinfo;
    
    // Generate "hints" for the DNS lookup (namely, search for both IPv4 and IPv6 addresses)
    struct addrinfo hints;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    
    char* service = [[url scheme] UTF8String];
    
    if(url.port) {
        NSString *portString = [NSString stringWithFormat: @"%@", [url port]];
        service = [portString UTF8String];
    }
    
    // Step 2). Find the address of the URL requested
    
    // The getaddrinfo() function shall translate the name of a service location (for example, a host name) and/or a service name, and it shall return a set of socket addresses and associated information to be used in creating a socket with which to address the specified service.
    // A zero return value for getaddrinfo() indicates successful completion; a non-zero return value indicates failure.
    // For more information, go to https://pubs.opengroup.org/onlinepubs/009696699/functions/getaddrinfo.html
    DNSServiceRef sdRef = NULL;
    DNSServiceFlags flags = kDNSServiceFlagsTimeout; // Set flags as needed

    dispatch_group_t group = dispatch_group_create();
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    __block BOOL resolutionCompleted = NO;
    __block struct addrinfo *addrinfoIPv4 = NULL;
    __block struct addrinfo *addrinfoIPv6 = NULL;

    // Start the IPv4 resolution
    dispatch_group_async(group, queue, ^{
        status = cellular_getaddrinfo([[url host] UTF8String], service, &hints, &addrinfoIPv4, sdRef, flags, kDNSServiceProtocol_IPv4);
        if (status == 0 && addrinfoIPv4 != NULL) {
            @synchronized (semaphore) {
                if (!resolutionCompleted) {
                    addrinfoPointer = addrinfoIPv4;
                    resolutionCompleted = YES;
                    dispatch_semaphore_signal(semaphore);
                }
            }
        }
    });

    // Start the IPv6 resolution
    dispatch_group_async(group, queue, ^{
        status = cellular_getaddrinfo([[url host] UTF8String], service, &hints, &addrinfoIPv6, sdRef, flags, kDNSServiceProtocol_IPv6);
        if (status == 0 && addrinfoIPv6 != NULL) {
            @synchronized (semaphore) {
                if (!resolutionCompleted) {
                    addrinfoPointer = addrinfoIPv6;
                    resolutionCompleted = YES;
                    dispatch_semaphore_signal(semaphore);
                }
            }
        }
    });

    // Wait for the first resolution to complete
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    // Clean up the other addrinfo if it was also resolved
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (addrinfoIPv4 && addrinfoIPv4 != addrinfoPointer) {
            freeaddrinfo(addrinfoIPv4);
        }
        if (addrinfoIPv6 && addrinfoIPv6 != addrinfoPointer) {
            freeaddrinfo(addrinfoIPv6);
        }
    });

    if (status || addrinfoPointer == NULL) {
        freeifaddrs(ifaddrPointer);
        printf("Error occurred, cannot find remote address of requested URL");
        sessionResult.status = CellularSessionCannotFindRemoteAddressOfRemoteUrl;
        return sessionResult;
    }
    
    addrinfo = addrinfoPointer;
    
    while (addrinfo) {
        switch (addrinfo->ai_addr->sa_family) {
            case AF_INET: // IPv4
            case AF_INET6: // IPv6
                [remoteAddresses addObject:[[SocketAddress alloc] initWithSockaddr:addrinfo->ai_addr]];
                break;
        }
        addrinfo = addrinfo->ai_next;
    }

    // Define the local address (which is the cellular data IP address) and define the remote address (which is the URL we're trying to reach)
    if ((localAddress = [[localAddresses filteredArrayUsingPredicate:ipv6Predicate] lastObject]) && (remoteAddress = [[remoteAddresses filteredArrayUsingPredicate:ipv6Predicate] lastObject])) {
        // Select the IPv6 route, if possible
    } else if ((localAddress = [[localAddresses filteredArrayUsingPredicate:ipv4Predicate] lastObject]) && (remoteAddress = [[remoteAddresses filteredArrayUsingPredicate:ipv4Predicate] lastObject])) {
        // Select the IPv4 route, if possible (and no IPv6 route is available)
    } else {
        // No route found, abort
        freeaddrinfo(addrinfoPointer);
        printf("Error occurred, no routes found for HTTP request");
        sessionResult.status = CellularSessionCannotFindRoutesForHttpRequest;
        return sessionResult;
    }
    
    // Step 3). Bind and connect socket to the addresses obtained from steps 1) and 2).
    
    // Instantiate a new socket
    int sock = socket(localAddress.sockaddr->sa_family, SOCK_STREAM, 0);
    if(sock == -1) {
        printf("Error occurred, cannot instantiate socket");
        sessionResult.status = CellularSessionUnableToInstantiateSockets;
        return sessionResult;
    }
    
    // Bind the socket to the local address
    bind(sock, localAddress.sockaddr, localAddress.size);
    
    // Connect to the remote address using the socket
    status = connect(sock, remoteAddress.sockaddr, remoteAddress.size);
    if (status) {
        freeaddrinfo(addrinfoPointer);
        printf("Error occurred, cannot connect socket to remote address");
        sessionResult.status = CellularSessionCannotConnectSocketToRemoteAddress;
        return sessionResult;
    }
    
    // Create the HTTP request string
    NSString *requestString = [NSString
                               stringWithFormat:@"GET %@%@ HTTP/1.1\r\nHost: %@%@\r\nAccept: */*\r\n",
                               [url path],
                               [url query] ? [@"?" stringByAppendingString:[url query]] : @"",
                               [url host],
                               [url port] ? [@":" stringByAppendingFormat:@"%@", [url port]] : @""];
    
    requestString = [requestString stringByAppendingString:@"Connection: close\r\n\r\n"];
    
    const char* request = [requestString UTF8String];

    char buffer[4096];
    NSMutableData *responseData = [NSMutableData dataWithCapacity:0];

    // Step 4). Invoke the HTTP request using the instantiated socket
    
    if ([[url scheme] isEqualToString:@"http"]) {
        write(sock, request, strlen(request));
        
        int received = 0;
        int total = sizeof(buffer)-1;
        do {
            int bytes = (int)read(sock, buffer+received, total-received);
            if (bytes < 0) {
                printf("Error occurred while reading HTTP response");
                sessionResult.status = CellularSessionErrorReadingHttpResponse;
                return sessionResult;
            } else if(bytes==0) {
                break;
            }
            
            received += bytes;
        } while (received < total);
        // Append the received data to responseData
        [responseData appendBytes:buffer length:received];
    } else { // Setup SSL if the URL is HTTPS
        // SSLCreateContext allocates and returns a new context.
        SSLContextRef context = SSLCreateContext(kCFAllocatorDefault, kSSLClientSide, kSSLStreamType);
        
        // SSLSetIOFuncs specifies functions that perform the network I/O operations. We must call this function prior to calling the SSLHandshake function.
        status = SSLSetIOFuncs(context, ssl_read, ssl_write);
        if (status) {
            SSLClose(context);
            CFRelease(context);
            NSString *errorMessage = @"Error occurred, cannot specify SSL functions needed to perform the network I/O operations, error code:";
            errorMessage = [errorMessage stringByAppendingString:[@(status) stringValue]];
            printf("%s", [errorMessage UTF8String]);
            sessionResult.status = CellularSessionCannotSpecifySSLFunctionsNeeded;
            return sessionResult;
        }
        
        // SSLSetConnection specifies an I/O connection for a specific session. We must establish a connection before creating a secure session.
        status = SSLSetConnection(context, (SSLConnectionRef)&sock);
        if (status) {
            SSLClose(context);
            CFRelease(context);
            NSString *errorMessage = @"Error occurred while specifying SSL I/O connection with peer, error code:";
            errorMessage = [errorMessage stringByAppendingString:[@(status) stringValue]];
            printf("%s", [errorMessage UTF8String]);
            sessionResult.status = CellularSessionCannotSpecifySSLIOConnection;
            return sessionResult;
        }
        
        // SSLSetPeerDomainName verifies the common name field in the peer’s certificate. If we call this function and the common name in the certificate does not match the value you specify in the peerName parameter (2nd parameter), then handshake fails and returns an error
        status = SSLSetPeerDomainName(context, [[url host] UTF8String], strlen([[url host] UTF8String]));
        if (status) {
            SSLClose(context);
            CFRelease(context);
            NSString *errorMessage = @"Error occurred, the common name of the peer's certificate doesn't match with URL being requested";
            errorMessage = [errorMessage stringByAppendingString:[@(status) stringValue]];
            printf("%s", [errorMessage UTF8String]);
            sessionResult.status = CellularSessionPeersCertificateDoesNotMatchWithRequestedUrl;
            return sessionResult;
        }

        do {
            // SSLHandshake performs the SSL handshake. On successful return, the session is ready for normal secure communication using the functions SSLRead and SSLWrite.
            status = SSLHandshake(context);
        } while (status == errSSLWouldBlock); // Repeat SSL handshake until it doesn't error out.
        if (status) {
            SSLClose(context);
            CFRelease(context);
            NSString *errorMessage = @"Error occurred while performing SSL handshake, error code:";
            errorMessage = [errorMessage stringByAppendingString:[@(status) stringValue]];
            printf("%s", [errorMessage UTF8String]);
            sessionResult.status = CellularSessionErrorPerformingSSLHandshake;
            return sessionResult;
        } 
        
        size_t processed = 0;
        // SSLWrite performs a typical application-level write operation.
        status = SSLWrite(context, request, strlen(request), &processed);
        if (status) {
            SSLClose(context);
            CFRelease(context);
            NSString *errorMessage = @"Error occurred while performing SSL write operation, error code:";
            errorMessage = [errorMessage stringByAppendingString:[@(status) stringValue]];
            printf("%s", [errorMessage UTF8String]);
            sessionResult.status = CellularSessionErrorPerformingSSLWriteOperation;
            return sessionResult;
        }
        
        do {
            // SSLRead performs a typical application-level read operation.
            status = SSLRead(context, buffer, sizeof(buffer) - 1, &processed);

            if (status == noErr && processed > 0) {
                // Append the received data to responseData
                [responseData appendBytes:buffer length:processed];
            } else if (status == errSSLWouldBlock) {
                // No more data available
                SSLClose(context);
                CFRelease(context);
                status = noErr;
                break;
            } else {
                // No data received
                break;
            }
        } while (status == noErr);

        if (status && status != errSSLClosedGraceful) {
            SSLClose(context);
            CFRelease(context);
            NSString *errorMessage = @"Error occurred, SSL session didn't close gracefully after performing SSL read operation, error code:";
            errorMessage = [errorMessage stringByAppendingString:[@(status) stringValue]];
            printf("%s", [errorMessage UTF8String]);
            sessionResult.status = CellularSessionSSLSessionDidNotCloseGracefullyAfterPerformingSSLReadOperation;
            return sessionResult;

        }
    }

    NSString *response = [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding];

    // Step 5). Parse the HTTP response and check whether it contains a redirect HTTP code
    
    if ([response rangeOfString:@"HTTP/"].location == NSNotFound) {
        printf("Error occurred, unknown HTTP response");
        sessionResult.status = CellularSessionUnknownHttpResponse;
        return sessionResult;
    }
    
    NSUInteger prefixLocation = [response rangeOfString:@"HTTP/"].location + 9;
    
    NSRange toReturnRange = NSMakeRange(prefixLocation, 1);
    
    NSString* urlResponseCode = [response substringWithRange:toReturnRange];
    
    // If the HTTP response contains a HTTP redirect code, obtain the redirect URL (which is found from the Location header), and return a string containing the redirect URL.
    // For example, "REDIRECT:https://redirect_url.com"
    if ([urlResponseCode isEqualToString:@"3"]) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Location: (.*)\r\n" options:NSRegularExpressionCaseInsensitive error:NULL];
        
        NSArray *myArray = [regex matchesInString:response options:0 range:NSMakeRange(0, [response length])] ;
        
        NSString* redirectLink = @"";
        
        for (NSTextCheckingResult *match in myArray) {
            NSRange matchRange = [match rangeAtIndex:1];
            redirectLink = [response substringWithRange:matchRange];
        }
        
        response = @"REDIRECT:";
        response = [response stringByAppendingString:redirectLink];
    }

    sessionResult.status = CellularSessionSuccess;
    sessionResult.result = response;

    return sessionResult;
}

@end
