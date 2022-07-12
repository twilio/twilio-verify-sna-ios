//
//  TwilioVerifySNA.swift
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

/// Private enum to validate and handle current network status
private enum NetworkStatus {
    case connected
    case disconnected
    case unknown
}

open class TwilioVerifySNA {
    // MARK: - Properties
    private var networkStatus: NetworkStatus = .unknown
    private let requestProcessor: RequestManagerProtocol

    /// By using cellular interface type we can validate only cellular availably.
    private lazy var monitor = NWPathMonitor(
        requiredInterfaceType: .cellular
    )

    // MARK: - Class lifecycle

    /**
     Developer notes: `RequestManager` and `NetworkRequestProvider` are meant to be for internal use,
     so it is on purpose that this dependencies are not injectables.
     */
    public init() {
        requestProcessor = RequestManager(
            networkProvider: NetworkRequestProvider()
        )
        startMonitoringNetwork()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Private methods

    private func startMonitoringNetwork() {
        let backgroundQueue = DispatchQueue(
            label: "InternetConnectionMonitor"
        )

        monitor.pathUpdateHandler = { [weak self] pathUpdateHandler in
            self?.networkStatus = pathUpdateHandler.status == .satisfied ?
                .connected :
                .disconnected
        }

        monitor.start(queue: backgroundQueue)
    }
}

// MARK: - TwilioVerifySNAProtocol
extension TwilioVerifySNA: TwilioVerifySNAProtocol {
    public func processURL(
        _ url: String,
        onComplete: ProcessURLResult
    ) {
        guard networkStatus == .connected else {
            return onComplete(.failure(.cellularNetworkNotAvailable))
        }

        onComplete(.success)
    }
}

// MARK: - Associated errors and results
extension TwilioVerifySNA {
    /// Docs
    public enum Error: LocalizedError {
        case cellularNetworkNotAvailable

        public var errorDescription: String? {
            switch self {
                case .cellularNetworkNotAvailable:
                    return "cellular network not available"
            }
        }
    }
}
