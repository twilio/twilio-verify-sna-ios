//
//  TwilioVerifySNAError.swift
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

public enum TwilioVerifySNAError: TwilioVerifySNAErrorProtocol, Equatable {
    case cellularNetworkNotAvailable
    case requestError(cause: RequestManager.RequestError)

    public var description: String {
        switch self {
            case .requestError(let cause):
                return """
                        Error processing the SNAURL request,
                        cause: \(cause.errorDescription ?? "Undefined")
                    """

            case .cellularNetworkNotAvailable:
                return "Cellular network not available"
        }
    }

    public var technicalError: String {
        switch self {
            case .requestError(let cause):
                return """
                    Request manager got an error processing the SNAURL request,
                    cause: \(cause.technicalError)
                    """

            case .cellularNetworkNotAvailable:
                return """
                        "The network monitor established that a cellular network is not available,
                        if you are running on a simulator or a device with no sim card for development
                        use the `setEnvironment()` method.
                        """
        }
    }

    public static func == (
        lhs: TwilioVerifySNAError,
        rhs: TwilioVerifySNAError
    ) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }
}
