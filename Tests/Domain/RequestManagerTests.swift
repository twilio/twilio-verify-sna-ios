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
import SNANetworking

@testable import TwilioVerifySNA

final class RequestManagerTests: XCTestCase {

    private var sut: RequestManager?
    private var networkProvider: MockNetworkRequestProvider!

    override func setUp() {
        networkProvider = .init()
        sut = RequestManager(networkProvider: networkProvider)
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

    func test_validUrl_shouldResponseWithSuccess() {
        // Arrange
        networkProvider.mockedResult = .success("ErrorCode=0&ErrorDescription=Success")
        let validURL = """
        https://mi-sbox.dnlsrv.com/msbox/idbrrecv2/v1?data=$2Eg9s82DAF2&2F+RN×7MI&3D%3D&cipherSalt=f6uZEIaNPTCgildi
        """

        // Act
        sut?.processSNAURL(validURL) { result in
            switch result {
                // Assert
                case .success: break
                case .failure(let error):
                    XCTFail("This url should be valid, should not fail. error \(error)")
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
}
