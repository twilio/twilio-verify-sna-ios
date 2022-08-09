//
//  RequestManager.swift
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

/// RequestManager:
/// Handles the SNA URL validation logic, communicates with `NetworkRequestProvider` and `TwilioVerifySession`.
public final class RequestManager {

    // MARK: - Properties

    /// Network provider used for handling networking operations,
    /// you could inject your own but you have to make sure that it will use only cellular network.
    private let networkProvider: NetworkRequestProviderProtocol

    // MARK: - Constants

    /// Constants used for validating the SNA URL results, this may change if the provider changes the implementation.
    private enum Constants {
        static let redirectionPath = "REDIRECT:"
        static let successPath = "ErrorCode=0&ErrorDescription=Success"
    }

    // MARK: - Class Lifecycle

    public init(
        networkProvider: NetworkRequestProviderProtocol
    ) {
        self.networkProvider = networkProvider
    }

    // MARK: - Private Methods

    /// Method to process the SNA URL result (that is a string url), this method will determine if the
    /// result needs to be redirected and processed again, or if it is completed.
    /// - Parameters:
    ///   - result: Result received from previous request.
    ///   - onComplete: Callback used for notify the request result, no return is needed.
    private func processRequestResult(
        _ result: String,
        onComplete: @escaping ProcessSNAURLResult
    ) {
        if result.contains(Constants.redirectionPath), !result.contains(Constants.successPath) {
            let redirectionUrl = getRedirectionUrl(for: result)
            return processSNAURL(redirectionUrl, onComplete: onComplete)
        }

        guard result.contains(Constants.successPath) else {
            return onComplete(.failure(.noResultFromUrl))
        }

        onComplete(.success)
    }

    /// When a SNA URL request finishes, it returns a string url with a possible redirect url,
    /// for instance: `REDIRECT:https://google.com`, so this method deletes the `redirect` part and
    /// returns a clean url.
    /// - Parameter url: Redirection URL
    /// - Returns: Clean URL
    private func getRedirectionUrl(for url: String) -> String {
        url.replacingOccurrences(of: Constants.redirectionPath, with: String())
    }
}

// MARK: - RequestProcessorProtocol
extension RequestManager: RequestManagerProtocol {

    /// Method to process the SNA URL. This method will handle the url via cellular network using the `NetworkRequestProviderProtocol` dependency.
    /// - Parameters:
    ///   - url: SNA URL retrieved from backend
    ///   - onComplete: Closure with Result<Void, Error> to handle scenarios.
    public func processSNAURL(
        _ url: String,
        onComplete: @escaping ProcessSNAURLResult
    ) {
        guard let url = URL(string: url) else {
            onComplete(.failure(.invalidUrl))
            return
        }

        networkProvider.performRequest(
            url: url
        ) { [weak self] result in

            guard let self = self else {
                return onComplete(.failure(.instanceNotFound))
            }

            switch result {
                case .failure(let cause):
                    onComplete(.failure(.networkingError(cause: cause)))

                case .success(let response):
                    self.processRequestResult(response, onComplete: onComplete)
            }
        }
    }
}

#if DEBUG
extension RequestManager {
    func getRedirectionUrl_forTesting(for url: String) -> String {
        getRedirectionUrl(for: url)
    }

    func processRequestResult_forTesting(
        _ result: String,
        onComplete: @escaping ProcessSNAURLResult
    ) {
        processRequestResult(result, onComplete: onComplete)
    }
}
#endif
