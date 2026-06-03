//
//  RequestManagerTests.swift
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

import XCTest

@testable import TwilioVerifySNA

final class RequestManagerTests: XCTestCase {

    private var sut: RequestManager?

    override func setUp() {
        sut = RequestManager(networkProvider: MockNetworkRequestProvider())
    }

    override func tearDown() {
        sut = nil
    }

    func test_invalidUrl_shouldResponseWithError() {
        // Arrange
        let invalidUrl = ""
        let expectedError: RequestManager.RequestError = .invalidUrl

        // Act
        sut?.processSNAURL(invalidUrl) { result in
            switch result {
                case .success:
                    XCTFail("This url should be invalid, should not succeed")

                case .failure(let cause):
                    // Assert
                    XCTAssertNotNil(cause.errorDescription)
                    XCTAssertNotNil(cause.technicalError)
                    XCTAssertTrue(cause == expectedError, "Unexpected result")
            }
        }
    }

    func test_redirectionUrl_shouldGetRedirectUrl() {
        // Arrange
        let url = """
        REDIRECT:https://mi-sbox.dnlsrv.com/msbox/idbrrecv2/v1?&air=false&cipherSalt=f6uZEIaNPTCgildi&state=1&SKEY=yowMtSAnJj4j7
        """
        let expectedRedirectUrl = """
        https://mi-sbox.dnlsrv.com/msbox/idbrrecv2/v1?&air=false&cipherSalt=f6uZEIaNPTCgildi&state=1&SKEY=yowMtSAnJj4j7
        """

        // Act
        let redirectionUrlResult = sut?.getRedirectionUrl_forTesting(for: url)

        // Assert
        XCTAssertEqual(redirectionUrlResult, expectedRedirectUrl)
    }

    func test_successUrl_shouldFinishProperly() {
        // Arrange
        let resultUrl = """
            REDIRECT:https://google.com/Redirect?ErrorCode=0&ErrorDescription=Success&Carrier=VZWSIM
        """

        // Act
        sut?.processRequestResult_forTesting(
            resultUrl,
            onComplete: { result in
                switch result {
                        // Assert
                    case .success:
                        XCTAssert(true)

                    case .failure:
                        XCTFail("Unexpected failure")
                }
            }
        )
    }

    func test_processSNAURL_withTimeout_shouldPassTimeoutToNetworkProvider() {
        // Arrange
        let mockNetworkProvider = MockNetworkRequestProvider()
        sut = RequestManager(networkProvider: mockNetworkProvider)
        let validUrl = "https://mi-sbox.dnlsrv.com/msbox/id/t20AHVnl?data=test"
        let expectedTimeout: TimeInterval = 15.0

        // Act
        sut?.processSNAURL(validUrl, timeout: expectedTimeout) { _ in }

        // Assert
        XCTAssertEqual(mockNetworkProvider.lastReceivedTimeout, expectedTimeout)
    }

    func test_processSNAURL_withNilTimeout_shouldPassNilToNetworkProvider() {
        // Arrange
        let mockNetworkProvider = MockNetworkRequestProvider()
        sut = RequestManager(networkProvider: mockNetworkProvider)
        let validUrl = "https://mi-sbox.dnlsrv.com/msbox/id/t20AHVnl?data=test"

        // Act
        sut?.processSNAURL(validUrl) { _ in }

        // Assert
        XCTAssertNil(mockNetworkProvider.lastReceivedTimeout)
    }

    func test_processSNAURL_withTimeout_whenTimeoutError_shouldReturnNetworkingError() {
        // Arrange
        let mockConnection = MockCellularConnection()
        mockConnection.makeResult = .failure(.timeout)
        let mockNetworkProvider = MockNetworkRequestProvider(connection: mockConnection)
        sut = RequestManager(networkProvider: mockNetworkProvider)
        let validUrl = "https://mi-sbox.dnlsrv.com/msbox/id/t20AHVnl?data=test"
        let expectedError: RequestManager.RequestError = .networkingError(cause: .timeout)

        // Act
        sut?.processSNAURL(validUrl, timeout: 5.0) { result in
            // Assert
            switch result {
                case .success:
                    XCTFail("Should not succeed")
                case .failure(let cause):
                    XCTAssertEqual(cause, expectedError)
            }
        }
    }

    func test_processRequestResult_withTimeout_shouldPassTimeoutOnRedirect() {
        // Arrange
        let mockNetworkProvider = MockNetworkRequestProvider()
        sut = RequestManager(networkProvider: mockNetworkProvider)
        let redirectResult = "REDIRECT:https://example.com/next-hop?data=test"
        let expectedTimeout: TimeInterval = 8.0

        // Act
        sut?.processRequestResult_forTesting(
            redirectResult,
            timeout: expectedTimeout,
            onComplete: { _ in }
        )

        // Assert - timeout was passed through to the network provider during redirect
        XCTAssertEqual(mockNetworkProvider.lastReceivedTimeout, expectedTimeout)
    }
}
