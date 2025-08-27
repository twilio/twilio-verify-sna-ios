//
//  CellularConnection+Models.swift
//  TwilioVerifySNA
//
//  Created by Alejandro Orozco Builes on 25/08/25.
//

import Foundation

public enum ConnectionError: Error {
    case invalidURL
    case connectionFailed(Error)
    case requestFailed(Error)
    case invalidResponse
    case httpResponseParsingFailed
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public struct RequestOptions {
    public let method: HTTPMethod
    public let headers: [String: String]
    public let body: Data?

    public init(
        method: HTTPMethod = .post,
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.method = method
        self.headers = headers
        self.body = body
    }
}
