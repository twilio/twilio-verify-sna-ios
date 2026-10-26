//
//  LegacyCellularConnection.swift
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

/// Adapter that exposes the socket based Objective-C `CellularSession` through `CellularConnectionProtocol`.
/// - Note: The underlying implementation is blocking and can't be cancelled, so the timeout only stops
/// waiting for the result; the socket finishes in the background and its result is dropped.
public final class LegacyCellularConnection: CellularConnectionProtocol {

    // MARK: - Properties

    private let session: CellularSessionProtocol
    private let availabilityCheck: (@escaping (Bool) -> Void) -> Void
    private let queue = DispatchQueue(
        label: "LegacyCellularConnectionQueue",
        qos: .userInitiated,
        attributes: .concurrent
    )

    // MARK: - Initializer

    public init(
        session: CellularSessionProtocol = CellularSession(),
        availabilityCheck: @escaping (@escaping (Bool) -> Void) -> Void = { CellularConnection().isAvailable(completion: $0) }
    ) {
        self.session = session
        self.availabilityCheck = availabilityCheck
    }

    // MARK: - CellularConnectionProtocol

    public func isAvailable(completion: @escaping (Bool) -> Void) {
        availabilityCheck(completion)
    }

    /// - Note: `ipVersion` is ignored, the legacy implementation resolves IPv6 and IPv4 on its own.
    public func makeRequest(
        url: URL,
        options: RequestOptions = RequestOptions(),
        using ipVersion: NWProtocolIP.Options.Version = .any,
        completion: @escaping (Result<String, ConnectionError>) -> Void
    ) {
        guard url.host != nil else {
            completion(.failure(.invalidURL))
            return
        }

        let lock = NSLock()
        var hasCompleted = false
        let completeOnce: (Result<String, ConnectionError>) -> Void = { result in
            lock.lock()
            let alreadyCompleted = hasCompleted
            hasCompleted = true
            lock.unlock()
            guard !alreadyCompleted else { return }
            completion(result)
        }

        queue.async { [session] in
            let sessionResult = session.performRequest(url)
            Logger.log("Legacy cellular logs:\n\(SNALogger.getText() ?? "")", lineNumber: #line)

            guard sessionResult.status == .success else {
                return completeOnce(.failure(.legacyFailure(sessionResult.status)))
            }
            guard let result = sessionResult.result else {
                return completeOnce(.failure(.invalidResponse))
            }
            completeOnce(.success(result))
        }

        if let timeout = options.timeout {
            queue.asyncAfter(deadline: .now() + timeout) {
                Logger.log("Legacy cellular request timed out after \(timeout)s")
                completeOnce(.failure(.timeout))
            }
        }
    }
}
