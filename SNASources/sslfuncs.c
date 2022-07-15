// Original implementation and credits to BENJAMIN BRYANT BUDIMAN: https://github.com/boku-inc/boku-wifi-ios
//
//  sslfuncs.c
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

#import "sslfuncs.h"

/**
 A customized read function that secure transport calls to read data from the connection.

 @param connection A connection reference.
 @param data On return, your callback should overwrite the memory at this location with the data read from the connection.
 @param data_length On input, a pointer to an integer representing the length of the data in bytes. On return, your callback should overwrite that integer with the number of bytes actually transferred.
 
 @return A result code.
 */
OSStatus ssl_read(SSLConnectionRef connection, void *data, size_t *data_length) {
	int socket = *(int *)connection;
	ssize_t written = read(socket, data, *data_length);
	if (written < *data_length) {
		*data_length = written;
		return errSSLWouldBlock;
	} else {
		*data_length = written;
		return noErr;
	}
}

/**
 A customized write function that secure transport calls to write data to the connection.

 @param connection A connection reference.
 @param data A pointer to the data to write to the connection. You must allocate this memory before calling this function.
 @param data_length Before calling, an integer representing the length of the data in bytes. On return, this is the number of bytes actually transferred.
 
 @return A result code.
 */
OSStatus ssl_write(SSLConnectionRef connection, const void *data, size_t *data_length) {
	int socket = *(int *)connection;
	ssize_t written = write(socket, data, *data_length);
	if (written < *data_length) {
		*data_length = written;
		return errSSLWouldBlock;
	} else {
		*data_length = written;
		return noErr;
	}
}
