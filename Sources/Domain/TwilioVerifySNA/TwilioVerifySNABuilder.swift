//
//  TwilioVerifySNABuilder.swift
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

public class TwilioVerifySNABuilder {
    /// Builds a `TwilioVerifySNA` instance.
    /// - Parameters:
    ///   - cellularImplementation: Cellular transport to start with, defaults to `.legacy`. It can be changed later
    ///   through `TwilioVerifySNA.cellularImplementation`.
    ///   - requestManager: Custom request manager. When provided, it owns its transport and `cellularImplementation` is ignored.
    public static func build(
        cellularImplementation: CellularImplementation = .legacy,
        requestManager: RequestManagerProtocol? = nil
    ) -> TwilioVerifySNA {
        if let requestManager {
            return TwilioVerifySNASession(requestManager: requestManager)
        }

        let connection = SwitchableCellularConnection(implementation: cellularImplementation)
        return TwilioVerifySNASession(
            requestManager: RequestManager(
                networkProvider: NetworkRequestProvider(cellularConnection: connection)
            ),
            switchableConnection: connection
        )
    }
}
