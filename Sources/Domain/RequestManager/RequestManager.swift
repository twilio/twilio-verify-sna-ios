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

public final class RequestManager {

    // MARK: - Properties
    
    private let networkProvider: NetworkRequestProviderProtocol

    // MARK: - Constants

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

    private func processRequestResult(
        _ result: String,
        onComplete: @escaping ProcessEVURLResult
    ) {
        if result.contains(Constants.redirectionPath), !result.contains(Constants.successPath) {
            let redirectionUrl = getRedirectionUrl(for: result)
            return processEVURL(redirectionUrl, onComplete: onComplete)
        }

        guard result.contains(Constants.successPath) else {
            return onComplete(.failure(.noResultFromUrl))
        }

        onComplete(.success)
    }

    private func getRedirectionUrl(for url: String) -> String {
        url.replacingOccurrences(of: Constants.redirectionPath, with: String())
    }
}

// MARK: - RequestProcessorProtocol
extension RequestManager: RequestManagerProtocol {
    public func processEVURL(
        _ url: String,
        onComplete: @escaping ProcessEVURLResult
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
        onComplete: @escaping ProcessEVURLResult
    ) {
        processRequestResult(result, onComplete: onComplete)
    }
}
#endif
