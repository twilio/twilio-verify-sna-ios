//
//  MockRequestManager.swift
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

struct MockRequestManager: RequestManagerProtocol {

    let shouldFail: Bool
    let expectedError: RequestManager.RequestError?

    func processSNAURL(
        _ url: String,
        onComplete: @escaping ProcessSNAURLResult
    ) {
        if shouldFail {
            let error =  (expectedError ?? .instanceNotFound)
            return onComplete(.failure(error))
        }

        let networkProvider = MockNetworkRequestProvider()

        networkProvider.performRequest(url: URL(string: url)!) { result in
            switch result {
                case .success:
                    onComplete(.success)
                case .failure(let error):
                    onComplete(.failure(.networkingError(cause: error)))
            }
        }
    }
}
