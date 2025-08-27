//
//  CellularConnection+Models.swift
//  TwilioVerifySNA
//
//  Created by Alejandro Orozco Builes on 25/08/25.
//

import Foundation

/// Represents possible errors that can occur during cellular network connections
public enum ConnectionError: Error, LocalizedError, Equatable {
    /// URL is invalid or cannot be processed
    case invalidURL
    /// Connection establishment failed
    case connectionFailed(Error)
    /// Request transmission or processing failed
    case requestFailed(Error)
    /// Indicates that a redirection attempt failed and returned an error.
    case redirectionFailed(Error)
    /// Received response is invalid or cannot be parsed
    case invalidResponse
    /// HTTP response parsing encountered an error
    case httpResponseParsingFailed

    public var errorDescription: String? {
        switch self {
            case .invalidURL: return "Invalid URL"
            case .connectionFailed(let error): return "Connection failed: \(error)"
            case .redirectionFailed(let error): return "Redirection failed: \(error)"
            case .requestFailed(let error): return "Request failed: \(error)"
            case .invalidResponse: return "Invalid response"
            case .httpResponseParsingFailed: return "HTTP response parsing failed"
        }
    }

    public static func == (lhs: ConnectionError, rhs: ConnectionError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.httpResponseParsingFailed, .httpResponseParsingFailed):
            return true
        case let (.connectionFailed(lhs), .connectionFailed(rhs)),
             let (.requestFailed(lhs), .requestFailed(rhs)),
             let (.redirectionFailed(lhs), .redirectionFailed(rhs)):
            return lhs.localizedDescription == rhs.localizedDescription
        default:
            return false
        }
    }
}

/// Represents standard HTTP request methods
public enum HTTPMethod: String {
    /// GET request method
    case get = "GET"
    /// POST request method
    case post = "POST"
    /// PUT request method
    case put = "PUT"
    /// DELETE request method
    case delete = "DELETE"
}

/// Configuration options for network requests
public struct RequestOptions {
    /// HTTP method for the request
    public let method: HTTPMethod
    /// Custom headers to include in the request
    public let headers: [String: String]
    /// Optional request body data
    public let body: Data?

    /// Initializes request options with default or custom parameters
    /// - Parameters:
    ///   - method: HTTP method (defaults to GET)
    ///   - headers: Custom request headers (defaults to empty)
    ///   - body: Optional request body data (defaults to nil)
    public init(
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.method = method
        self.headers = headers
        self.body = body
    }
}
