//
//  CellularConnection.swift
//
//
//  Created by Alejandro Orozco Builes on 19/01/24.
//

import Foundation
import Network

public protocol CellularConnectionProtocol {
    /// Checks if the SNA service is available over a cellular interface
    /// - Parameters:
    ///   - completion: Closure called with a boolean result (success or failure)
    func isAvailable(
        completion: @escaping (Bool) -> Void
    )

    /// Initiates a network request using a cellular connection
    /// - Parameters:
    ///   - url: The URL to connect to
    ///   - options: Custom request configuration options
    ///   - ipVersion: IP protocol version preference (IPv4/IPv6)
    ///   - completion: Closure called with request result (success or failure)
    func makeRequest(
        url: URL,
        options: RequestOptions,
        using ipVersion: NWProtocolIP.Options.Version,
        completion: @escaping (Result<String, ConnectionError>) -> Void
    )
}

/// A networking class that provides cellular-specific HTTP/HTTPS connection capabilities
/// using Network.framework's NWConnection for cellular network requests.
public class CellularConnection: CellularConnectionProtocol {

    // MARK: - Constants

    private enum Constants {
        static let isAvailableHost: NWEndpoint.Host = "verify.twilio.com"
        static let isAvailablePort: NWEndpoint.Port = 443
    }

    // MARK: - Properties

    private var connection: NWConnection?

    // MARK: - Initializer

    public init() {}

    // MARK: - Public Methods

    public func isAvailable(
        completion: @escaping (Bool) -> Void
    ) {
        let endpoint = NWEndpoint.hostPort(host: Constants.isAvailableHost, port: Constants.isAvailablePort)
        let parameters = NWParameters.tcp
        configureParameters(parameters)

        let connection = NWConnection(to: endpoint, using: parameters)

        connection.stateUpdateHandler = { state in
            switch state {
                case .ready:
                    // Cellular network is working
                    Logger.log("Cellular connectivity check to \(Constants.isAvailableHost):\(Constants.isAvailablePort) successful - connection is ready")
                    completion(true)
                    connection.cancel()
                case .failed, .cancelled:
                    guard connection.state != .cancelled else { break; }
                    // Cellular not working
                    Logger.log("Cellular connectivity check to \(Constants.isAvailableHost):\(Constants.isAvailablePort) \(state == .cancelled ? "was cancelled" : "failed to connect")")
                    completion(false)
                    connection.cancel()
                case .waiting(let error):
                    // Cellular network is down
                    if #available(iOS 16.4, *) {
                        if error.errorCode == ENETDOWN {
                            Logger.log("Cellular connectivity check to \(Constants.isAvailableHost):\(Constants.isAvailablePort) failed - network interface is down (error: \(error))")
                            completion(false)
                            connection.cancel()
                        }
                    } else if case let .posix(posixError) = error, posixError == .ENETDOWN {
                        Logger.log("Cellular connectivity check to \(Constants.isAvailableHost):\(Constants.isAvailablePort) failed - network interface is down (error: \(posixError))")
                        completion(false)
                        connection.cancel()
                    }
                default:
                    break
            }
        }

        connection.start(queue: DispatchQueue.global(qos: .background))
    }

    public func makeRequest(
        url: URL,
        options: RequestOptions = RequestOptions(),
        using ipVersion: NWProtocolIP.Options.Version = .any,
        completion: @escaping (Result<String, ConnectionError>) -> Void
    ) {
        guard url.host != nil else {
            completion(.failure(.invalidURL))
            return
        }

        do {
            try createConnection(url, using: ipVersion)
            prepareRequest(url: url, options: options, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - Internal Methods

    /// Configures network parameters to ensure cellular-only connectivity
    /// - Parameter parameters: The NWParameters object to configure
    /// - Note: Sets cellular as required interface, prohibits other interfaces, allows expired DNS, and enables interactive multipath
    private func configureParameters(_ parameters: NWParameters) {
        parameters.requiredInterfaceType = .cellular
        parameters.prohibitedInterfaceTypes = [.wifi, .wiredEthernet, .loopback]
        parameters.expiredDNSBehavior = .allow
        parameters.multipathServiceType = .interactive
    }

    /// Creates a cellular network connection using Network framework
    /// - Parameters:
    ///   - url: The target URL for the connection
    ///   - ipVersion: IP protocol version preference (default is any)
    /// - Throws: `ConnectionError` if URL is invalid or connection cannot be established
    /// - Note: Configures connection to use only cellular network and interactive multipath
    private func createConnection(
        _ url: URL,
        using ipVersion: NWProtocolIP.Options.Version = .any
    ) throws(ConnectionError) {
        let port: NWEndpoint.Port = url.port.map { NWEndpoint.Port(integerLiteral: UInt16($0)) } ?? (url.scheme == "https" ? .https : .http)

        guard let urlHost = url.host else { throw ConnectionError.invalidURL }

        let host = NWEndpoint.Host(urlHost)
        let endpoint = NWEndpoint.hostPort(host: host, port: port)
        let parameters: NWParameters = url.scheme == "https" ? NWParameters(tls: .init()) : NWParameters(tls: nil)
        configureParameters(parameters)

        if let protocolOption = parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
            protocolOption.version = ipVersion
        }

        Logger.log("NWConnection using host \(host) and port \(port) to \(endpoint), with parameters: \(parameters)", lineNumber: #line)
        connection = NWConnection(to: endpoint, using: parameters)
    }

    /// Prepares the HTTP request by constructing request headers and setting up connection state handler
    /// - Parameters:
    ///   - url: The target URL for the request
    ///   - options: Request configuration options
    ///   - completion: Closure to be called with the request result
    /// - Note: Builds request string, adds headers, and sets up NWConnection state handling
    private func prepareRequest(
        url: URL,
        options: RequestOptions,
        completion: @escaping (Result<String, ConnectionError>) -> Void
    ) {
        var requestComponents = [
            "\(options.method.rawValue) \(url.path)\(url.query.map { "?" + $0 } ?? "") HTTP/1.1",
            "Host: \(url.host ?? "")",
            "Accept: */*",
            "Connection: close"
        ]

        // Add custom headers
        for (key, value) in options.headers {
            requestComponents.append("\(key): \(value)")
        }

        // Handle request body
        if let body = options.body {
            requestComponents.append("Content-Length: \(body.count)")
        }

        var requestString = requestComponents.joined(separator: "\r\n")
        requestString += "\r\n\r\n"

        if let body = options.body {
            requestString += String(data: body, encoding: .utf8) ?? ""
        }

        Logger.log("Request:\n\(requestString)", lineNumber: #line)

        connection?.stateUpdateHandler = { [weak self] newState in
            switch newState {
                case .ready:
                    self?.sendRequest(requestString, body: options.body, completion: completion)
                case .failed(let error):
                    Logger.log("Failed: \(error)", lineNumber: #line)
                    completion(.failure(ConnectionError.connectionFailed(error)))
                case .waiting(let error):
                    Logger.log("Waiting state: \(error)", lineNumber: #line)
                    completion(.failure(ConnectionError.connectionFailed(error)))
                case .cancelled:
                    Logger.log("Waiting state cancelled", lineNumber: #line)
                default:
                    break
            }
        }

        connection?.start(queue: .global())
    }

    /// Sends the prepared HTTP request over the network connection
    /// - Parameters:
    ///   - request: Formatted HTTP request string
    ///   - body: Optional request body data
    ///   - completion: Closure to be called with the send result
    /// - Note: Converts request to Data and sends via NWConnection
    private func sendRequest(
        _ request: String,
        body: Data?,
        completion: @escaping (Result<String, ConnectionError>) -> Void
    ) {
        let requestData = Data(request.utf8)
        var fullRequestData = requestData

        if let body = body {
            fullRequestData.append(body)
        }

        connection?.send(content: fullRequestData, completion: .contentProcessed { error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
            } else {
                self.receiveResponse(responseData: .init(), completion: completion)
            }
        })
    }

    /// Receives the network response in chunks
    /// - Parameters:
    ///   - responseData: Accumulated response data
    ///   - completion: Closure to be called with the full response
    /// - Note: Handles partial and complete network responses, including redirect detection
    private func receiveResponse(
        responseData: Data,
        completion: @escaping (Result<String, ConnectionError>) -> Void
    ) {
        var responseData = responseData
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }

            if let data = data {
                responseData.append(data)

                // Check if was a partial response with the location already in
                if let responseString = String(data: responseData, encoding: .ascii) {
                    if responseString.contains("HTTP/1.1 302") ||
                        responseString.contains("HTTP/1.1 301") ||
                        responseString.contains("Location:") {
                        self.processFullResponse(responseData, completion: completion)
                        return
                    }
                }
            }

            if isComplete {
                self.processFullResponse(responseData, completion: completion)
            } else if let error = error {
                Logger.log("Received error while receiving response: \(error)")
                completion(.failure(ConnectionError.requestFailed(error)))
            } else {
                self.receiveResponse(responseData: responseData, completion: completion)
            }
        }
    }

    /// Processes the full HTTP response
    /// - Parameters:
    ///   - responseData: Complete response data
    ///   - completion: Closure to be called with the parsed response
    /// - Note: Handles response cancellation, parsing, and redirect detection
    private func processFullResponse(
        _ responseData: Data,
        completion: @escaping (Result<String, ConnectionError>) -> Void
    ) {
        connection?.cancel()
        connection = nil

        guard let response = String(data: responseData, encoding: .ascii) else {
            Logger.log("Invalid response decoding")
            completion(.failure(ConnectionError.invalidResponse))
            return
        }

        Logger.log("Response:\n\(response)", lineNumber: #line)

        guard (response as NSString).range(of: "HTTP/").location != NSNotFound else {
            Logger.log("HTTP response parsing failed")
            completion(.failure(ConnectionError.httpResponseParsingFailed))
            return
        }

        let statusCodeRange = NSRange(location: (response as NSString).range(of: "HTTP/").location + 9, length: 3)
        let statusCode = (response as NSString).substring(with: statusCodeRange)

        if statusCode.hasPrefix("3") {
            handleRedirect(response: response, completion: completion)
        } else {
            completion(.success(response))
        }
    }

    /// Handles HTTP redirects by extracting the redirect URL
    /// - Parameters:
    ///   - response: Full HTTP response string
    ///   - completion: Closure to be called with the redirect URL or an error
    /// - Note: Uses regex to extract redirect URL from HTTP response
    private func handleRedirect(
        response: String,
        completion: @escaping (Result<String, ConnectionError>) -> Void
    ) {
        do {
            // Handle redirect for http & https urls
            let URLPattern = #"https?://\S+"#
            let regex = try NSRegularExpression(pattern: URLPattern, options: [])
            let match = regex.firstMatch(
                in: response,
                options: [],
                range: NSRange(location: 0, length: response.utf16.count)
            )

            if let match = match, let range = Range(match.range, in: response) {
                let redirectURL = String(response[range])
                let redirectResponse = "REDIRECT:" + redirectURL
                Logger.log("HTTP redirect to: \(redirectURL)")
                completion(.success(redirectResponse))
            } else {
                Logger.log("HTTP response parsing failed")
                completion(.failure(ConnectionError.httpResponseParsingFailed))
            }
        } catch {
            completion(.failure(.redirectionFailed(error)))
        }
    }
}
