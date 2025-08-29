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
@testable import TwilioVerifySNA

final class NetworkRequestProviderTests: XCTestCase {
    private var sut: NetworkRequestProvider?
    private var mockCellularConnection: MockCellularConnection?

    override func setUp() {
        super.setUp()
        mockCellularConnection = MockCellularConnection()
        sut = NetworkRequestProvider(
            cellularConnection: mockCellularConnection!
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
                switch result {
                    case .success: break;
                    case .failure:
                        XCTFail("Should not fail")
                }
            }
        )
    }

    func test_networkProvider_withInvalidRequest_shouldRespondWithExpectedError() {
        // Arrange
        mockCellularConnection?.result = .failure(.invalidURL)

        let urlString = "https://mi-sbox.dnlsrv.com/msbox/id/t20AHVnl?data=l%2BPA0m5y5sPgPl2"
        let expectedError = ConnectionError.invalidURL

        guard let url = URL(string: urlString) else {
            XCTFail("invalid URL")
            return
        }

        // Act
        sut?.performRequest(
            url: url,
            onComplete: { result in
                switch result {
                    case .success:
                        XCTFail("Should not succeed")
                    case .failure(let cause):
                        XCTAssertEqual(expectedError, cause)
                }
            }
        )
    }

    func test_errorAssociatedValues_shouldHaveValues() {
        // Arrange
        mockCellularConnection?.result = .failure(.httpResponseParsingFailed)

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
                        XCTAssertEqual(cause.localizedDescription, "HTTP response parsing failed")
                    default:
                        XCTFail("Unexpected success scenario.")
                }
            }
        )
    }
}
