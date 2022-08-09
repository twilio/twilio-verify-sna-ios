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

public typealias ProcessURLResult = Result<Void, TwilioVerifySNASession.Error>
public typealias ProcessURLCallback = (ProcessURLResult) -> Void

public protocol TwilioVerifySNA {
    func processURL(
        _ url: String,
        onComplete: @escaping ProcessURLCallback
    )

    @available(iOS 13, *)
    func processURL(_ url: String) async -> ProcessURLResult
}

/// This extension allow us to return a void in the 'success' scenario for Result
public extension Result where Success == Void {
    static var success: Result {
        return .success(())
    }
}
