//
//  NetworkRequestProviderTests.swift
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

final class NetworkRequestProviderTests: XCTestCase {
    private var sut: NetworkRequestProvider?

    override func setUp() {
        super.setUp()

        sut = NetworkRequestProvider(
            cellularSession: MockCellularSession()
        )
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
    }

    func test_networkProvider_withValidRequest_shouldRespondWithSuccessScenario() {
        // Arrange
        let urlString = "https://mi-sbox.dnlsrv.com/msbox/id/t20AHVnl?data=l%2BPA0m5y5sPgPl2"

        guard let url = URL(string: urlString) else {
            XCTFail("invalid URL")
            return
        }

        // Act
        sut?.performRequest(
            url: url,
            onComplete: { result in
                // Assert
                let status = String(describing: CellularSessionStatus.success)
                let expectedBehavior = Result<String, NetworkRequestProvider.RequestError>.success(status)
                XCTAssertEqual(result, expectedBehavior)
            }
        )
    }

    func test_networkProvider_withInvalidRequest_shouldRespondWithExpectedError() {
        // Arrange
        sut = NetworkRequestProvider(
            cellularSession: MockCellularSession(status: .cannotFindRoutesForHttpRequest)
        )

        let urlString = "https://mi-sbox.dnlsrv.com/msbox/id/t20AHVnl?data=l%2BPA0m5y5sPgPl2"
        let expectedError = Result<String, NetworkRequestProvider.RequestError>.failure(
            .cellularRequestError(cause: .cannotFindRoutesForHttpRequest)
        )

        guard let url = URL(string: urlString) else {
            XCTFail("invalid URL")
            return
        }

        // Act
        sut?.performRequest(
            url: url,
            onComplete: { result in
                // Assert
                XCTAssertEqual(result, expectedError)
            }
        )
    }

    func test_errorAssociatedValues_shouldHaveValues() {
        // Arrange
        sut = NetworkRequestProvider(
            cellularSession: MockCellularSession(status: .cannotFindRoutesForHttpRequest)
        )

        let urlString = "https://mi-sbox.dnlsrv.com/msbox/id/t20AHVnl?data=l%2BPA0m5y5sPgPl2"
        
        guard let url = URL(string: urlString) else {
            XCTFail("invalid URL")
            return
        }

        // Act
        sut?.performRequest(
            url: url,
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
