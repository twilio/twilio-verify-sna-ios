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

import Foundation
import SNANetworking

final class MockCellularSession: NSObject, CellularSessionProtocol {
    var status: CellularSessionStatus = .success
    var result: String? = ""
    var delay: TimeInterval = 0
    private(set) var receivedURLs: [URL] = []
    private(set) var ranOnMainThread: Bool?

    func performRequest(_ url: URL) -> CellularSessionResult {
        receivedURLs.append(url)
        ranOnMainThread = Thread.isMainThread
        if delay > 0 { Thread.sleep(forTimeInterval: delay) }
        let sessionResult = CellularSessionResult()
        sessionResult.status = status
        sessionResult.result = result
        return sessionResult
    }
}
