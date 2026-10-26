//
//  SwitchableCellularConnection.swift
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

/// Routes every call to the cellular implementation currently selected.
/// - Note: The selection is read once per call, so changing it never affects a request already in flight.
public final class SwitchableCellularConnection: CellularConnectionProtocol {

    // MARK: - Properties

    private let legacy: CellularConnectionProtocol
    private let networkFramework: CellularConnectionProtocol
    private let lock = NSLock()
    private var selected: CellularImplementation

    public var implementation: CellularImplementation {
        get {
            lock.lock()
            defer { lock.unlock() }
            return selected
        }
        set {
            lock.lock()
            selected = newValue
            lock.unlock()
        }
    }

    // MARK: - Initializer

    public init(
        implementation: CellularImplementation = .legacy,
        legacy: CellularConnectionProtocol = LegacyCellularConnection(),
        networkFramework: CellularConnectionProtocol = CellularConnection()
    ) {
        self.selected = implementation
        self.legacy = legacy
        self.networkFramework = networkFramework
    }

    // MARK: - CellularConnectionProtocol

    private var current: CellularConnectionProtocol {
        implementation == .legacy ? legacy : networkFramework
    }

    public func isAvailable(completion: @escaping (Bool) -> Void) {
        current.isAvailable(completion: completion)
    }

    public func makeRequest(
        url: URL,
        options: RequestOptions,
        using ipVersion: NWProtocolIP.Options.Version,
        completion: @escaping (Result<String, ConnectionError>) -> Void
    ) {
        current.makeRequest(url: url, options: options, using: ipVersion, completion: completion)
    }
}
