//
//  NetworkRequestProvider.swift
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

public final class NetworkRequestProvider {

    // MARK: - Properties

    private let cellularSession: CellularSessionProtocol

    // MARK: - Computed properties

    private lazy var networkRequestQueue = DispatchQueue(
        label: "NetworkRequestQueue"
    )

    // MARK: - Class lifecycle

    public init(
        cellularSession: CellularSessionProtocol
    ) {
        self.cellularSession = cellularSession
    }
}

// MARK: - NetworkRequestProviderProtocol
extension NetworkRequestProvider: NetworkRequestProviderProtocol {
    public func performRequest(
        url: URL,
        onComplete: @escaping NetworkRequestResult
    ) {
        networkRequestQueue.async {
            let networkOperationOnCellularData = self.cellularSession.performGetRequest(url)

            guard case .success = networkOperationOnCellularData.status else {
                onComplete(
                    .failure(.cellularRequestError(cause: networkOperationOnCellularData.status))
                )
                return
            }

            guard let result = networkOperationOnCellularData.result else {
                onComplete(.failure(.requestFinishedWithNoResult))
                return
            }

            onComplete(.success(result))
        }
    }
}
