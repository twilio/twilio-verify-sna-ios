//
//  MockNetworkRequestProvider.swift
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
import Network

@testable import TwilioVerifySNA

struct MockNetworkRequestProvider: NetworkRequestProviderProtocol {

    // MARK: - Properties

    let connection: CellularConnectionProtocol

    // MARK: - Initializer

    init(connection: CellularConnectionProtocol = MockCellularConnection()) {
        self.connection = connection
    }

    // MARK: - Public Methods

    func testCellularConnectivity(
        to host: String,
        port: UInt16,
        completion: @escaping (Bool) -> Void
    ) {
        connection.testCellularConnectivity(to: host, port: port, completion: completion)
    }

    func performRequest(url: URL, using ipVersion: NWProtocolIP.Options.Version, onComplete: @escaping NetworkRequestResult) {
        connection.makeRequest(url: url, options: .init(), using: .any, completion: onComplete)
    }
}
