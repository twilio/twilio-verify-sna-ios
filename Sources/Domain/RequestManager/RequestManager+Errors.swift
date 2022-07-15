//
//  RequestManager+Errors.swift
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

// MARK: - Associated errors

extension RequestManager {

    public enum RequestError: TwilioVerifySNAErrorProtocol, Equatable {
        case invalidUrl
        case noResultFromUrl
        case instanceNotFound
        case networkingError(cause: NetworkRequestProvider.RequestError)

        public var errorDescription: String? {
            switch self {
                case .noResultFromUrl:
                    return "Unable to get a valid result from the requested URL."

                case .instanceNotFound:
                    return "Unable to continue url process, instance not found."

                case .networkingError(let cause):
                    return "Networking error, cause: \(cause.errorDescription ?? "Undefined")"

                case .invalidUrl:
                    return "Invalid url, please check the format."
            }
        }

        public var technicalError: String? {
            switch self {
                case .noResultFromUrl:
                    return """
                        Unable to get a redirection path or a result path from the url,
                        probably the EVURL is corrupted (or maybe expired)
                    """

                case .instanceNotFound:
                    return """
                        weak self was nil, make sure that you are
                        instantiating as a dependency this SDK or lazy loading it,
                        do not use this SDK as a computed property.
                        """

                case .networkingError:
                    return errorDescription

                case .invalidUrl:
                    return "Unable to convert the url string to an Apple URL struct"
            }
        }

        public static func == (
            lhs: RequestManager.RequestError,
            rhs: RequestManager.RequestError
        ) -> Bool {
            String(describing: lhs) == String(describing: rhs)
        }
    }
}
