//
//  MockCellularSession.swift
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

class MockCellularSession: CellularSessionProtocol {
    let status: CellularSessionStatus

    init(status: CellularSessionStatus = .success) {
        self.status = status
    }

    func performRequest(_ url: URL) -> CellularSessionResult {
        let result = CellularSessionResult()
        result.status = status
        result.result = String(describing: status)

        return result
    }
}
