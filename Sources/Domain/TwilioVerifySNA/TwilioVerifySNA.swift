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
import SNANetworking

/// Private enum to validate and handle current network status
private enum NetworkStatus {
    case connected
    case disconnected
    case unknown
}

open class TwilioVerifySNA {

    // MARK: - Properties

    private var networkStatus: NetworkStatus = .unknown
    private let requestManager: RequestManagerProtocol
    private var waitForConnectionAccumulatedTime: Double = .zero

    // MARK: - Constants

    private enum Constants {
        static let waitForConnectionTimeInSeconds: Double = 0.5
        static let waitForConnectionToleranceInSeconds: Double = 4
    }

    // MARK: - Lazy loaded properties & queues

    private lazy var internetMonitoringQueue = DispatchQueue(
        label: "InternetConnectionMonitorQueue"
    )

    private lazy var urlRequestQueue = DispatchQueue(
        label: "UrlRequestQueue"
    )

    private lazy var monitor = NWPathMonitor(
        requiredInterfaceType: .cellular
    )

    // MARK: - Class lifecycle

    public init(
        requestManager: RequestManager = RequestManager(
            networkProvider: NetworkRequestProvider(
                cellularSession: CellularSession()
            )
        )
    ) {
        self.requestManager = requestManager
        startMonitoringNetwork()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Private methods

    private func startMonitoringNetwork() {
        monitor.pathUpdateHandler = { [weak self] pathUpdateHandler in
            self?.networkStatus = pathUpdateHandler.status == .satisfied ?
                .connected :
                .disconnected
        }

        monitor.start(
            queue: internetMonitoringQueue
        )
    }

    /**
     This method will wait until the NWPathMonitor gets a result for the networking result.
     */
    private func waitForConnectionResultAndContinue(
        with url: String,
        and completionHandler: @escaping ProcessURLResult
    ) {
        guard waitForConnectionAccumulatedTime < Constants.waitForConnectionToleranceInSeconds else {
            return completionHandler(.failure(.cellularNetworkNotAvailable))
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + Constants.waitForConnectionTimeInSeconds
        ) {
            self.waitForConnectionAccumulatedTime += Constants.waitForConnectionTimeInSeconds
            self.processURL(url, onComplete: completionHandler)
        }
    }

    private func handleURLRequest(
        _ url: String,
        onComplete: @escaping ProcessURLResult
    ) {
        if networkStatus == .unknown {
            return waitForConnectionResultAndContinue(
                with: url,
                and: onComplete
            )
        }

        waitForConnectionAccumulatedTime = .zero

        guard networkStatus == .connected else {
            return onComplete(.failure(.cellularNetworkNotAvailable))
        }

        requestManager.processSNAURL(
            url
        ) { result in
            switch result {
                case.failure(let cause):
                    onComplete(.failure(.requestError(cause: cause)))

                case .success:
                    onComplete(.success)
            }
        }
    }
}

// MARK: - TwilioVerifySNAProtocol
extension TwilioVerifySNA: TwilioVerifySNAProtocol {
    /**
     This method will process the URL requested from your backend.
     Please notice that this method will work entirely on a background thread and will respond on a background thread,
     so if you decide to update your UI once this method responses make sure to do it on the main thread using GCD.
     */
    public func processURL(
        _ url: String,
        onComplete: @escaping ProcessURLResult
    ) {
        urlRequestQueue.async {
            self.handleURLRequest(url, onComplete: onComplete)
        }
    }
}
