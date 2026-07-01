//
//  CellularConnectionTests.swift
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

final class CellularConnectionTests: XCTestCase {

    private var sut: CellularConnection!

    override func setUp() {
        super.setUp()
        sut = CellularConnection()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - makeRequest tests

    func test_makeRequest_withURLMissingHost_shouldReturnInvalidURLError() {
        // Arrange
        let url = URL(string: "file:///path/to/file")!
        let expectation = expectation(description: "Completion called")

        // Act
        sut.makeRequest(url: url, options: .init(), using: .any) { result in
            // Assert
            switch result {
                case .failure(let error):
                    XCTAssertEqual(error, .invalidURL)
                case .success:
                    XCTFail("Should not succeed with a URL missing host")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    // MARK: - processFullResponse tests

    func test_processFullResponse_withValid200Response_shouldReturnSuccess() {
        // Arrange
        let httpResponse = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<html>OK</html>"
        let responseData = Data(httpResponse.utf8)
        let expectation = expectation(description: "Completion called")

        // Act
        sut.processFullResponse(responseData) { result in
            // Assert
            switch result {
                case .success(let response):
                    XCTAssertTrue(response.contains("HTTP/1.1 200 OK"))
                case .failure:
                    XCTFail("Should succeed with a valid 200 response")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func test_processFullResponse_with302Redirect_shouldReturnRedirectURL() {
        // Arrange
        let httpResponse = "HTTP/1.1 302 Found\r\nLocation: https://example.com/redirect\r\n\r\n"
        let responseData = Data(httpResponse.utf8)
        let expectation = expectation(description: "Completion called")

        // Act
        sut.processFullResponse(responseData) { result in
            // Assert
            switch result {
                case .success(let response):
                    XCTAssertTrue(response.hasPrefix("REDIRECT:"))
                    XCTAssertTrue(response.contains("https://example.com/redirect"))
                case .failure:
                    XCTFail("Should succeed with a redirect response")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func test_processFullResponse_with301Redirect_shouldReturnRedirectURL() {
        // Arrange
        let httpResponse = "HTTP/1.1 301 Moved Permanently\r\nLocation: https://newdomain.com/path\r\n\r\n"
        let responseData = Data(httpResponse.utf8)
        let expectation = expectation(description: "Completion called")

        // Act
        sut.processFullResponse(responseData) { result in
            // Assert
            switch result {
                case .success(let response):
                    XCTAssertTrue(response.hasPrefix("REDIRECT:"))
                    XCTAssertTrue(response.contains("https://newdomain.com/path"))
                case .failure:
                    XCTFail("Should succeed with a 301 redirect response")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func test_processFullResponse_withEmptyData_shouldReturnHttpResponseParsingFailed() {
        // Arrange - empty Data converts to empty string, which has no "HTTP/" prefix
        let responseData = Data()
        let expectation = expectation(description: "Completion called")

        // Act
        sut.processFullResponse(responseData) { result in
            // Assert
            switch result {
                case .failure(let error):
                    XCTAssertEqual(error, .httpResponseParsingFailed)
                case .success:
                    XCTFail("Should fail with empty data")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func test_processFullResponse_withNonASCIIData_shouldReturnInvalidResponse() {
        // Arrange - invalid ASCII bytes that can't be decoded
        let responseData = Data([0xFF, 0xFE, 0x80, 0x81])
        let expectation = expectation(description: "Completion called")

        // Act
        sut.processFullResponse(responseData) { result in
            // Assert
            switch result {
                case .failure(let error):
                    XCTAssertEqual(error, .invalidResponse)
                case .success:
                    XCTFail("Should fail with non-ASCII data")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func test_processFullResponse_withNonHTTPResponse_shouldReturnParsingFailed() {
        // Arrange
        let nonHTTPResponse = "This is not an HTTP response"
        let responseData = Data(nonHTTPResponse.utf8)
        let expectation = expectation(description: "Completion called")

        // Act
        sut.processFullResponse(responseData) { result in
            // Assert
            switch result {
                case .failure(let error):
                    XCTAssertEqual(error, .httpResponseParsingFailed)
                case .success:
                    XCTFail("Should fail with non-HTTP response")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func test_processFullResponse_with404Response_shouldReturnSuccessWithBody() {
        // Arrange
        let httpResponse = "HTTP/1.1 404 Not Found\r\nContent-Type: text/html\r\n\r\nNot Found"
        let responseData = Data(httpResponse.utf8)
        let expectation = expectation(description: "Completion called")

        // Act
        sut.processFullResponse(responseData) { result in
            // Assert
            switch result {
                case .success(let response):
                    XCTAssertTrue(response.contains("404 Not Found"))
                case .failure:
                    XCTFail("Non-redirect, non-error status codes should return success")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    // MARK: - handleRedirect tests

    func test_handleRedirect_withValidHTTPSURL_shouldExtractURL() {
        // Arrange
        let response = "HTTP/1.1 302 Found\r\nLocation: https://example.com/callback?code=abc123\r\n\r\n"
        let expectation = expectation(description: "Completion called")

        // Act
        sut.handleRedirect(response: response) { result in
            // Assert
            switch result {
                case .success(let redirectResponse):
                    XCTAssertEqual(redirectResponse, "REDIRECT:https://example.com/callback?code=abc123")
                case .failure:
                    XCTFail("Should extract redirect URL")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func test_handleRedirect_withValidHTTPURL_shouldExtractURL() {
        // Arrange
        let response = "HTTP/1.1 302 Found\r\nLocation: http://insecure.example.com/path\r\n\r\n"
        let expectation = expectation(description: "Completion called")

        // Act
        sut.handleRedirect(response: response) { result in
            // Assert
            switch result {
                case .success(let redirectResponse):
                    XCTAssertEqual(redirectResponse, "REDIRECT:http://insecure.example.com/path")
                case .failure:
                    XCTFail("Should extract HTTP redirect URL")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func test_handleRedirect_withNoURL_shouldReturnParsingFailed() {
        // Arrange
        let response = "HTTP/1.1 302 Found\r\nLocation: /relative/path\r\n\r\n"
        let expectation = expectation(description: "Completion called")

        // Act
        sut.handleRedirect(response: response) { result in
            // Assert
            switch result {
                case .failure(let error):
                    XCTAssertEqual(error, .httpResponseParsingFailed)
                case .success:
                    XCTFail("Should fail when no absolute URL found")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func test_handleRedirect_withURLContainingQueryParams_shouldExtractFullURL() {
        // Arrange
        let response = "HTTP/1.1 302 Found\r\nLocation: https://mi-sbox.dnlsrv.com/msbox/id?air=false&cipherSalt=abc&state=1\r\n\r\n"
        let expectation = expectation(description: "Completion called")

        // Act
        sut.handleRedirect(response: response) { result in
            // Assert
            switch result {
                case .success(let redirectResponse):
                    XCTAssertTrue(redirectResponse.contains("air=false"))
                    XCTAssertTrue(redirectResponse.contains("cipherSalt=abc"))
                    XCTAssertTrue(redirectResponse.contains("state=1"))
                case .failure:
                    XCTFail("Should extract full URL with query params")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    // MARK: - RequestOptions timeout tests

    func test_requestOptions_withTimeout_shouldStoreValue() {
        // Arrange & Act
        let options = RequestOptions(timeout: 15.0)

        // Assert
        XCTAssertEqual(options.timeout, 15.0)
    }

    func test_requestOptions_withNilTimeout_shouldDefaultToNil() {
        // Arrange & Act
        let options = RequestOptions()

        // Assert
        XCTAssertNil(options.timeout)
    }

    func test_requestOptions_withAllParameters_shouldStoreCorrectly() {
        // Arrange
        let body = Data("test".utf8)

        // Act
        let options = RequestOptions(
            method: .post,
            headers: ["Authorization": "Bearer token"],
            body: body,
            timeout: 30.0
        )

        // Assert
        XCTAssertEqual(options.method, .post)
        XCTAssertEqual(options.headers["Authorization"], "Bearer token")
        XCTAssertEqual(options.body, body)
        XCTAssertEqual(options.timeout, 30.0)
    }

    // MARK: - ConnectionError tests

    func test_connectionError_timeout_shouldBeEquatable() {
        // Assert
        XCTAssertEqual(ConnectionError.timeout, ConnectionError.timeout)
        XCTAssertNotEqual(ConnectionError.timeout, ConnectionError.invalidURL)
        XCTAssertNotEqual(ConnectionError.timeout, ConnectionError.invalidResponse)
    }

    func test_connectionError_allCases_shouldHaveDescriptions() {
        // Arrange
        let errors: [ConnectionError] = [
            .invalidURL,
            .connectionFailed(NSError(domain: "test", code: 1)),
            .requestFailed(NSError(domain: "test", code: 2)),
            .redirectionFailed(NSError(domain: "test", code: 3)),
            .invalidResponse,
            .httpResponseParsingFailed,
            .timeout
        ]

        // Assert
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description")
            XCTAssertFalse(error.errorDescription!.isEmpty, "Error \(error) description should not be empty")
        }
    }

    func test_connectionError_equatable_sameAssociatedErrors_shouldBeEqual() {
        // Arrange
        let nsError = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "test error"])

        // Assert
        XCTAssertEqual(
            ConnectionError.connectionFailed(nsError),
            ConnectionError.connectionFailed(nsError)
        )
        XCTAssertEqual(
            ConnectionError.requestFailed(nsError),
            ConnectionError.requestFailed(nsError)
        )
        XCTAssertEqual(
            ConnectionError.redirectionFailed(nsError),
            ConnectionError.redirectionFailed(nsError)
        )
    }

    func test_connectionError_equatable_differentTypes_shouldNotBeEqual() {
        // Arrange
        let nsError = NSError(domain: "test", code: 1)

        // Assert
        XCTAssertNotEqual(ConnectionError.connectionFailed(nsError), ConnectionError.requestFailed(nsError))
        XCTAssertNotEqual(ConnectionError.invalidURL, ConnectionError.timeout)
        XCTAssertNotEqual(ConnectionError.invalidResponse, ConnectionError.httpResponseParsingFailed)
    }
}
