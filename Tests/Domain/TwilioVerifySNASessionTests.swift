//
//  TwilioVerifySNASessionTests.swift
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

@available(iOS 13, *)
final class TwilioVerifySNASessionTests: XCTestCase {

    private var sut = TwilioVerifySNASession()

    func test_invalidNetworkStatus_shouldResponseWithExpectedError() async {
        // Arrange
        let expectedError: TwilioVerifySNASession.Error = .cellularNetworkNotAvailable
        let mockUrl = "https://google.com"
        sut.set(networkStatus: .disconnected)

        // Act
        let result = await sut.processURL(mockUrl)

        switch result {
                // Assert
            case .failure(let cause):
                XCTAssertEqual(cause, expectedError)
                return

            default:
                XCTFail("Unexpected error received.")
                return
        }
    }

    func test_ProcessURL_shouldCommunicateErrorFromRequestManager() async {
        // Arrange
        let expectedError: RequestManager.RequestError = .noResultFromUrl
        let snaUrl = "https://mi-sbox.dnlsrv.com/msbox/id/t20AHVnl?data=l%2BPA0m5y5sPgPl2%2BpL3WeZrpnC8ijytmW4HqyqTztauaifjOCg8YSifXn8ItqF32Tice4vAhl0mIQ9K8%2F5xZC7Ot9y6cgPbqXMMj93v%2FqFCrmoZzXAYwPXlE%2BCdHVELxRdNZ80IrB1Ym35YOHFVYnjZ%2FY4vDeyveLrSe%2BaYM6MQkWDQZOVSSlXrY4hrCq7W%2B398mpvmk3PgWOAABpcTEzD1lg4YCu4FNSrWgthdtFG9kpOaXY1He2UbqRrLISmuBjwAmxaqzR5QUm0XTqUneaOrU79CXwuUBL9Q8bxg1jjn5uqQaPrNHvCSL%2F4cG3vc9&cipherSalt=upiokA9Mmxr6PYlS&redirect=https%3A%2F%2Fgoogle.com%2FRedirect&air=false"

        sut = TwilioVerifySNASession(
            requestManager: MockRequestManager(
                shouldFail: true,
                expectedError: .noResultFromUrl
            )
        )
        sut.set(networkStatus: .connected)

        // Act
        let result = await sut.processURL(snaUrl)

        switch result {
            case .failure(.requestError(let  cause)):
                // Assert
                XCTAssertEqual(cause, expectedError)

            default:
                XCTFail("Unexpected error received ")
        }
    }

    func test_errorAssociatedValues_shouldHaveValues() {
        // Arrange
        sut = TwilioVerifySNASession(
            requestManager: MockRequestManager(
                shouldFail: true,
                expectedError: .instanceNotFound
            )
        )
        sut.set(networkStatus: .connected)

        let urlString = "https://mi-sbox.dnlsrv.com/msbox/id/t20AHVnl?data=l%2BPA0m5y5sPgPl2"

        // Act
        sut.processURL(
            urlString,
            onComplete: { result in
                // Assert
                switch result {
                    case .failure(let cause):
                        XCTAssertNotNil(cause.errorDescription)
                        XCTAssertNotNil(cause.technicalError)
                    default:
                        XCTFail("Unexpected success scenario.")
                }
            }
        )
    }
}
