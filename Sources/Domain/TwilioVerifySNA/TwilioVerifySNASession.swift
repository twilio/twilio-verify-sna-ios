//
//  TwilioVerifySNASession.swift
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

final class TwilioVerifySNASession: TwilioVerifySNA {

    // MARK: - Properties

    private var networkStatus: NetworkStatus = .unknown
    private let requestManager: RequestManagerProtocol
    private var waitForConnectionAccumulatedTime: Double = .zero

    enum NetworkStatus {
        case connected
        case disconnected
        case unknown
    }

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

    init(
        requestManager: RequestManagerProtocol = RequestManager(
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

    // MARK: - Protocol implementation

    /// This method will process the SNA URL via different layers in order to provide a trusted validation of the identity of the user via the SNA URL.
    ///  - Note: This method work entirely on a background thread and will respond on a background thread.
    /// - Parameters:
    ///   - url: SNA URL provided by your backend.
    ///   - onComplete: Closure with `Result<Void, TwilioVerifySNASession.Error>`.
    func processURL(
        _ url: String,
        onComplete: @escaping ProcessURLCallback
    ) {
        urlRequestQueue.async {
            self.handleURLRequest(url, onComplete: onComplete)
        }
    }

    /// `processURL` method  async support.
    @available(iOS 13, *)
    func processURL(_ url: String) async -> ProcessURLResult {
        return await withCheckedContinuation { continuation in
            processURL(url) { result in
                continuation.resume(returning: result)
            }
        }
    }

    // MARK: - Private methods

    /// This method uses a `NWPathMonitor` to validate if the device has cellular network available.
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

    /// This method will wait until the NWPathMonitor gets a result for the networking result and then continue the `processURL` request.
    /// - Note: When the developer runs for the fist time the method `processURL`, the monitor has not started yet, therefore it is necessary to suspend
    /// for a moment the execution of the method in order to wait the network status.
    /// - Parameters:
    ///   - url: SNA URL provided by your backend
    ///   - completionHandler: Closure with `Result<Void, TwilioVerifySNASession.Error>`
    private func waitForConnectionResultAndContinue(
        with url: String,
        and completionHandler: @escaping ProcessURLCallback
    ) {
        guard waitForConnectionAccumulatedTime < Constants.waitForConnectionToleranceInSeconds else {
            return completionHandler(.failure(.cellularNetworkNotAvailable))
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + Constants.waitForConnectionTimeInSeconds
        ) { [weak self] in
            self?.waitForConnectionAccumulatedTime += Constants.waitForConnectionTimeInSeconds
            self?.processURL(url, onComplete: completionHandler)
        }
    }

    /// This method will process the SNA URL request and validate that the network is in optimal conditions to perform the network request.
    /// - Parameters:
    ///   - url: SNA URL provided by your backend
    ///   - onComplete: Closure with `Result<Void, TwilioVerifySNASession.Error>`
    private func handleURLRequest(
        _ url: String,
        onComplete: @escaping ProcessURLCallback
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

#if DEBUG
extension TwilioVerifySNASession {
    func set(networkStatus: NetworkStatus) {
        monitor.pathUpdateHandler = nil
        monitor.cancel()
        self.networkStatus = networkStatus
    }
}
#endif
