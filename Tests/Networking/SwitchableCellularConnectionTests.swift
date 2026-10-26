//
//  SwitchableCellularConnectionTests.swift
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

final class SwitchableCellularConnectionTests: XCTestCase {

    private var legacy: MockCellularConnection!
    private var modern: MockCellularConnection!
    private var sut: SwitchableCellularConnection!
    private let url = URL(string: "https://verify.twilio.com")!

    override func setUp() {
        super.setUp()
        legacy = MockCellularConnection()
        legacy.makeResult = .success("legacy")
        modern = MockCellularConnection()
        modern.makeResult = .success("modern")
        sut = SwitchableCellularConnection(legacy: legacy, networkFramework: modern)
    }

    private func request() -> String? {
        var value: String?
        sut.makeRequest(url: url, options: .init(), using: .any) {
            if case .success(let response) = $0 { value = response }
        }
        return value
    }

    func test_defaultImplementation_isLegacy() {
        XCTAssertEqual(sut.implementation, .legacy)
        XCTAssertEqual(request(), "legacy")
    }

    func test_switchingImplementation_routesToNetworkFramework() {
        sut.implementation = .networkFramework
        XCTAssertEqual(request(), "modern")
        sut.implementation = .legacy
        XCTAssertEqual(request(), "legacy")
    }

    func test_initialImplementation_isRespected() {
        sut = SwitchableCellularConnection(implementation: .networkFramework, legacy: legacy, networkFramework: modern)
        XCTAssertEqual(request(), "modern")
    }

    func test_concurrentSetAndRequest_doesNotCrash() {
        DispatchQueue.concurrentPerform(iterations: 500) { index in
            if index % 2 == 0 {
                sut.implementation = index % 4 == 0 ? .legacy : .networkFramework
            } else {
                _ = request()
            }
        }
    }
}
