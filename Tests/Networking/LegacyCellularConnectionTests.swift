//
//  LegacyCellularConnectionTests.swift
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

final class LegacyCellularConnectionTests: XCTestCase {

    private var session: MockCellularSession!
    private var sut: LegacyCellularConnection!
    private let url = URL(string: "https://verify.twilio.com/path")!

    override func setUp() {
        super.setUp()
        session = MockCellularSession()
        sut = LegacyCellularConnection(session: session, availabilityCheck: { $0(true) })
    }

    private func perform(
        url: URL? = nil,
        options: RequestOptions = RequestOptions()
    ) -> Result<String, ConnectionError> {
        let exp = expectation(description: "completion")
        var captured: Result<String, ConnectionError>!
        sut.makeRequest(url: url ?? self.url, options: options, using: .any) {
            captured = $0
            exp.fulfill()
        }
        waitForExpectations(timeout: 3)
        return captured
    }

    func test_makeRequest_withMissingHost_returnsInvalidURL() {
        XCTAssertEqual(perform(url: URL(string: "file:///x")!), .failure(.invalidURL))
        XCTAssertTrue(session.receivedURLs.isEmpty)
    }

    func test_makeRequest_success_passesResultThrough() {
        session.result = "REDIRECT:https://example.com"
        XCTAssertEqual(perform(), .success("REDIRECT:https://example.com"))
        XCTAssertEqual(session.receivedURLs, [url])
    }

    func test_makeRequest_failureStatus_mapsToLegacyFailure() {
        session.status = .cannotConnectSocketToRemoteAddress
        session.result = nil
        XCTAssertEqual(perform(), .failure(.legacyFailure(.cannotConnectSocketToRemoteAddress)))
    }

    func test_makeRequest_successWithoutResult_returnsInvalidResponse() {
        session.result = nil
        XCTAssertEqual(perform(), .failure(.invalidResponse))
    }

    func test_makeRequest_runsOffMainThread() {
        _ = perform()
        XCTAssertEqual(session.ranOnMainThread, false)
    }

    func test_makeRequest_timeout_completesOnceWithTimeout() {
        session.delay = 0.5
        let exp = expectation(description: "completion")
        var calls = 0
        var captured: Result<String, ConnectionError>?
        sut.makeRequest(url: url, options: RequestOptions(timeout: 0.1), using: .any) {
            calls += 1
            captured = $0
            exp.fulfill()
        }
        waitForExpectations(timeout: 3)
        // Let the late session result arrive and be dropped.
        let settle = expectation(description: "settle")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) { settle.fulfill() }
        waitForExpectations(timeout: 3)
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(captured, .failure(.timeout))
    }

    func test_isAvailable_delegatesToAvailabilityCheck() {
        let exp = expectation(description: "available")
        sut.isAvailable { XCTAssertTrue($0); exp.fulfill() }
        waitForExpectations(timeout: 1)
    }
}
