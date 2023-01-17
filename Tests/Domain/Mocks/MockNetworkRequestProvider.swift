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
import SNANetworking

@testable import TwilioVerifySNA

class MockNetworkRequestProvider: NetworkRequestProviderProtocol {

    let session: CellularSessionProtocol
    var mockedResult: Result<String, NetworkRequestProvider.RequestError>?

    init(session: CellularSessionProtocol = MockCellularSession()) {
        self.session = session
    }

    func performRequest(url: URL, onComplete: @escaping NetworkRequestResult) {
        switch mockedResult {
            case .success(let result):
                return onComplete(.success(result))
            case .failure(let error):
                return onComplete(.failure(error))
            default: break
        }

        let request = session.performRequest(url)

        guard let result = request.result else {
            return onComplete(.failure(.requestFinishedWithNoResult))
        }

        onComplete(.success(result))
    }
}
