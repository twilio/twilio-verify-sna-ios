//
//  NetworkLayer.swift
//  TwilioVerifySNADemo
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

/**
 This network layer is created with the only purpose of helping the demo app to perform network requests.
 In the best practices you probably use your own networking layer or third parties like Alamofire.
 */
final class NetworkLayer {
    func post<Response: Decodable, Request: Encodable>(
        to url: String,
        request: Request,
        onComplete: @escaping (Response?) -> Void
    ) {
        guard let url = URLComponents(string: url)?.url else {
            return onComplete(nil)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try? JSONEncoder().encode(request)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: urlRequest) { data, _, error in
            guard let data = data, error == nil else {
                onComplete(nil)
                return
            }

            guard let convertedResponse = try? JSONDecoder().decode(Response.self, from: data) else {
                onComplete(nil)
                return
            }

            onComplete(convertedResponse)

        }.resume()
    }
}
