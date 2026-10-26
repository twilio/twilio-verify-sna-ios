//
//  sslfuncs.h
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

#ifndef sslfuncs_h
#define sslfuncs_h

#import <CoreFoundation/CoreFoundation.h>
#import <Security/SecureTransport.h>

OSStatus ssl_read(SSLConnectionRef connection, void *data, size_t *data_length);
OSStatus ssl_write(SSLConnectionRef connection, const void *data, size_t *data_length);

#endif /* sslfuncs_h */
