//
//  CellularGetAddrinfo.m
//
//
//  Created by Alejandro Orozco Builes on 24/01/24.
//

#import <Foundation/Foundation.h>
#import "CellularGetAddrinfo.h"
#include <net/if.h>
#import <netdb.h>

int global_port;

int cellular_getaddrinfo(const char *nodename, const char *servname,
                       const struct addrinfo *hints, struct addrinfo **res,
                       DNSServiceRef sdRef, DNSServiceFlags flags,
                       DNSServiceProtocol protocol) {
    sa_family_t family = AF_INET;
    
    if (protocol == kDNSServiceProtocol_IPv4) {
        family = AF_INET;
    } else if (protocol == kDNSServiceProtocol_IPv6) {
        family = AF_INET6;
    }

    // Get the cellular network interface index
    unsigned int interfaceIndex = 0;
    struct ifaddrs *interfaces = NULL;
    if (getifaddrs(&interfaces) == 0) {
        for (struct ifaddrs *ifa = interfaces; ifa != NULL; ifa = ifa->ifa_next) {
            if (ifa->ifa_addr->sa_family == family &&
                strcmp(ifa->ifa_name, "pdp_ip0") == 0 &&
                ifa->ifa_flags & IFF_UP) {
                interfaceIndex = if_nametoindex(ifa->ifa_name);
                break;
            }
        }
        freeifaddrs(interfaces);
        interfaces = NULL;
    }

    // Check if cellular interface index found
    if (interfaceIndex == 0) {
        NSLog(@"Error: Could not find cellular network interface");
        return 1; // Indicate general failure
    }

    // Set the global port number
    if (strcmp(servname, "http") == 0) {
        global_port = 80;
    } else if (strcmp(servname, "https") == 0) {
        global_port = 443;
    } else {
        global_port = atoi(servname);
    }

    // Use DNSServiceGetAddrInfo with cellular interface index
    DNSServiceErrorType err = DNSServiceGetAddrInfo(&sdRef, flags, interfaceIndex, protocol,
                                                      nodename, cellular_getaddrinfo_callback, res);

    DNSServiceProcessResult(sdRef);
    DNSServiceRefDeallocate(sdRef);

    // Convert DNSServiceErrorType to POSIX error code
    if (err == kDNSServiceErr_NoError) {
        return 0;
    } else {
        return htonl(err); // Map DNSService errors to POSIX errors
    }
}

void cellular_getaddrinfo_callback(DNSServiceRef sdRef, DNSServiceFlags flags,
                                 uint32_t interfaceIndex, DNSServiceErrorType err,
                                 const char *hostname, const struct sockaddr *address,
                                 uint32_t ttl, void *context) {
    // Handle the results or errors received in the callback
    if (err == kDNSServiceErr_NoError) {

        struct addrinfo **results = (struct addrinfo **)context;

        *results = (struct addrinfo *)malloc(sizeof(struct addrinfo));
        if (*results == NULL) {
            NSLog(@"Error: Could not allocate memory for results");
            return;
        }
        memset(*results, 0, sizeof(struct addrinfo));

        // Determine the size of the address structure
        size_t addrSize = 0;
        if (address->sa_family == AF_INET) {
            addrSize = sizeof(struct sockaddr_in);
        } else if (address->sa_family == AF_INET6) {
            addrSize = sizeof(struct sockaddr_in6);
        } else {
            NSLog(@"Error: Unsupported address family");
            free(*results);
            *results = NULL;
            return;
        }

        (*results)->ai_addr = (struct sockaddr *)malloc(addrSize);
        if ((*results)->ai_addr == NULL) {
            NSLog(@"Error: Could not allocate memory for ai_addr");
            free(*results);
            *results = NULL;
            return;
        }

        memcpy((*results)->ai_addr, address, addrSize);

        (*results)->ai_family = address->sa_family;
        (*results)->ai_socktype = SOCK_STREAM; // Set to SOCK_STREAM for TCP
        (*results)->ai_protocol = IPPROTO_TCP; // Set to IPPROTO_TCP for TCP
        (*results)->ai_addrlen = (socklen_t)addrSize;

        // If the address is IPv4 or IPv6, set the port number
        if (address->sa_family == AF_INET) {
            ((struct sockaddr_in *)(*results)->ai_addr)->sin_port = htons(global_port);
        } else if (address->sa_family == AF_INET6) {
            ((struct sockaddr_in6 *)(*results)->ai_addr)->sin6_port = htons(global_port);
        }
    } else {
        NSLog(@"DNSServiceGetAddrInfo failed: %d", err);
        struct addrinfo **results = (struct addrinfo **)context;
        *results = NULL;
    }
}
