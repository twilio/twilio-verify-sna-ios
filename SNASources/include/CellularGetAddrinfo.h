//
//  CellularGetAddrinfo.h
//
//
//  Created by Alejandro Orozco Builes on 24/01/24.
//

#import <Foundation/Foundation.h>
#import <dns_sd.h>
#import <arpa/inet.h>
#import <ifaddrs.h>

// Cellular GetAddrInfo forces the DNS resolution through cellular network
int cellular_getaddrinfo(const char *nodename, const char *servname,
                       const struct addrinfo *hints, struct addrinfo **res,
                       DNSServiceRef sdRef, DNSServiceFlags flags,
                       DNSServiceProtocol protocol);

// DNSServiceGetAddrInfoReply Callback retrieve the DNS resolution
void cellular_getaddrinfo_callback(DNSServiceRef sdRef, DNSServiceFlags flags,
                                 uint32_t interfaceIndex, DNSServiceErrorType err,
                                 const char *hostname, const struct sockaddr *address,
                                 uint32_t ttl, void *context);
