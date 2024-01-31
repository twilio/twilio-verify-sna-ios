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
import Network
import SNANetworking

public final class NetworkRequestProvider {

    // MARK: - Properties

    private let cellularSession: CellularSessionProtocol
    private let cellularConnection: CellularConnection = .init()

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

    /// This method will perform a regular GET operation via network using the cellular layer.
    /// - Note: This method **will not** work if you are using a simulator or a device with no SIM-CARD (and internet working).
    /// - Parameters:
    ///   - url: SNA URL provided by your backend.
    ///   - onComplete: Closure with `Result<Void, NetworkRequestProvider.RequestError>`.
    public func performRequest(
        url: URL,
        using ipVersion: NWProtocolIP.Options.Version = .any,
        onComplete: @escaping NetworkRequestResult
    ) {
        Logger.log("Start cellular connection", lineNumber: #line)
        cellularConnection.makeRequest(url: url, using: ipVersion) { response in
            switch response {
                case .success(let response):
                    onComplete(.success(response))
                case .failure(let error):
                    onComplete(.failure(.cellularRequestError(cause: .unexpectedError)))
                    Logger.log("Received error: \(error.localizedDescription)", lineNumber: #line)
            }
        }
//        networkRequestQueue.async {
//            let networkOperationOnCellularData = self.cellularSession.performRequest(url)
//
//            guard case .success = networkOperationOnCellularData.status else {
//                onComplete(
//                    .failure(.cellularRequestError(cause: networkOperationOnCellularData.status))
//                )
//                return
//            }
//
//            guard let result = networkOperationOnCellularData.result else {
//                onComplete(.failure(.requestFinishedWithNoResult))
//                return
//            }
//
//            onComplete(.success(result))
//        }
    }
}
