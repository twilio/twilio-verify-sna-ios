//
//  CellularConnection.swift
//
//
//  Created by Alejandro Orozco Builes on 19/01/24.
//

import Foundation
import Network
import SNANetworking

public class CellularConnection {

    // MARK: - Properties

    private var connection: NWConnection?

    // MARK: - Public Methods

    public func makeRequest(
        url: URL,
        options: RequestOptions = RequestOptions(),
        using ipVersion: NWProtocolIP.Options.Version = .any,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard url.host != nil else {
            completion(.failure(ConnectionError.invalidURL))
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

    private func createConnection(
        _ url: URL,
        using ipVersion: NWProtocolIP.Options.Version = .any
    ) throws {
        let port: NWEndpoint.Port = url.port.map { NWEndpoint.Port(integerLiteral: UInt16($0)) } ?? (url.scheme == "https" ? .https : .http)
        
        guard let urlHost = url.host else {
            throw ConnectionError.invalidURL
        }

        let host = NWEndpoint.Host(urlHost)
        let endpoint = NWEndpoint.hostPort(host: host, port: port)
        let parameters: NWParameters = url.scheme == "https" ? NWParameters(tls: .init()) : NWParameters(tls: nil)

        parameters.requiredInterfaceType = .cellular
        parameters.prohibitedInterfaceTypes = [.wifi, .wiredEthernet, .loopback]

        if let protocolOption = parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
            protocolOption.version = ipVersion
        }

        Logger.log("NWConnection using host \(host) and port \(port) to \(endpoint), with parameters: \(parameters)", lineNumber: #line)

        connection = NWConnection(to: endpoint, using: parameters)
    }
    
    private func prepareRequest(
        url: URL,
        options: RequestOptions,
        completion: @escaping (Result<String, Error>) -> Void
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
                completion(.failure(ConnectionError.connectionFailed(error)))
            default:
                break
            }
        }
        
        connection?.start(queue: .global())
    }
    
    private func sendRequest(
        _ request: String, 
        body: Data?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let requestData = Data(request.utf8)
        var fullRequestData = requestData
        
        if let body = body {
            fullRequestData.append(body)
        }

        connection?.send(content: fullRequestData, completion: .contentProcessed { error in
            if let error = error {
                completion(.failure(ConnectionError.requestFailed(error)))
            } else {
                self.receiveResponse(responseData: .init(), completion: completion)
            }
        })
    }
    
    private func receiveResponse(
        responseData: Data,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        var responseData = responseData
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let data = data {
                responseData.append(data)
            }
            
            if isComplete {
                self.processFullResponse(responseData, completion: completion)
            } else if let error = error {
                completion(.failure(ConnectionError.requestFailed(error)))
            } else {
                self.receiveResponse(responseData: responseData, completion: completion)
            }
        }
    }
    
    private func processFullResponse(
        _ responseData: Data,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        connection?.cancel()
        connection = nil
        
        guard let response = String(data: responseData, encoding: .ascii) else {
            completion(.failure(ConnectionError.invalidResponse))
            return
        }

        Logger.log("Response:\n\(response)", lineNumber: #line)

        guard (response as NSString).range(of: "HTTP/").location != NSNotFound else {
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
    
    private func handleRedirect(
        response: String,
        completion: @escaping (Result<String, Error>) -> Void
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
                completion(.success(redirectResponse))
            } else {
                completion(.failure(ConnectionError.httpResponseParsingFailed))
            }
        } catch {
            completion(.failure(error))
        }
    }
}
