//
//  CustomGetAddrinfo.h
//
//
//  Created by Alejandro Orozco Builes on 24/01/24.
//

#import <Foundation/Foundation.h>
#import <dns_sd.h>
#import <arpa/inet.h>
#import <ifaddrs.h>

@interface DNSResolver : NSObject

// Public method to start DNS-SD service and resolve address
- (void)startDNSSDServiceForHostname:(NSString *)hostname;

@end

// Function declaration with corrected parameters
int custom_getaddrinfo(const char *nodename, const char *servname,
                       const struct addrinfo *hints, struct addrinfo **res,
                       DNSServiceRef sdRef, DNSServiceFlags flags,
                       DNSServiceProtocol protocol);

// Declare the callback function with corrected signature
void custom_getaddrinfo_callback(DNSServiceRef sdRef, DNSServiceFlags flags,
                                 uint32_t interfaceIndex, DNSServiceErrorType err,
                                 const char *hostname, const struct sockaddr *address,
                                 uint32_t ttl, void *context);
