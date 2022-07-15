//
//  NetworkRequestProvider+Errors.swift
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

// MARK: - Associated errors

extension NetworkRequestProvider {

    public enum RequestError: TwilioVerifySNAErrorProtocol {
        case requestFinishedWithNoResult
        case cellularRequestError(cause: CellularSessionStatus)

        public var errorDescription: String? {
            switch self {
                case .requestFinishedWithNoResult:
                    return "No response from request"

                case .cellularRequestError(let cause):
                    return "Error processing the URL via cellular network, cause: \(cause)"
            }
        }

        public var technicalError: String? {
            switch self {
                case .requestFinishedWithNoResult:
                    return """
                        The request was successful (200 status code)
                        but the networking layer was unable to get the response
                    """

                case .cellularRequestError:
                    return errorDescription
            }
        }
    }
}
