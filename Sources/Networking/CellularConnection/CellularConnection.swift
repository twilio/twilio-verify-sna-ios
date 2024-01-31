//
//  CellularConnection.swift
//
//
//  Created by Alejandro Orozco Builes on 19/01/24.
//

import Foundation
import Network
import SNANetworking

class CellularConnection {
    private var connection: NWConnection?
    private var didConnect: Bool = false

    enum Errors: Error {
        case unknownResponse
        case cantFoundHTTPResponse
    }

    func makeRequest(
        url: URL,
        using ipVersion: NWProtocolIP.Options.Version = .any,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        createConnection(url, using: ipVersion)
        // Set up your request, handle the response, and call the completion handler
        var requestString = String(format: "POST %@%@ HTTP/1.2\r\nHost: %@%@\r\nAccept: */*\r\nContent-Type: application/json\r\nContent-Length: 0\r\n",
                                    url.path,
                                    url.query != nil ? "?" + url.query! : "",
                                    url.host ?? "",
                                    url.port != nil ? ":" + String(url.port!) : "")

        requestString += "Connection: close\r\n\r\n"

        connection?.pathUpdateHandler = { path in
            Logger.log(String(describing: path), lineNumber: #line)
        }

        connection?.stateUpdateHandler = { newState in
            Logger.log(String(describing: newState), lineNumber: #line)
            switch newState {
            case .ready:
                self.sendRequest(requestString, completion: completion)
            case .failed(let error):
                completion(.failure(error))
            default:
                break
            }
        }

        connection?.betterPathUpdateHandler = { betterPath in
            Logger.log("Better preferred over other path: \(String(describing: betterPath))", lineNumber: #line)
        }

        connection?.viabilityUpdateHandler = { viability in
            Logger.log("Viability: \(String(describing: viability))", lineNumber: #line)
        }

        connection?.start(queue: .global())
    }

    private func createConnection(
        _ url: URL,
        using ipVersion: NWProtocolIP.Options.Version = .any
    ) {
        let port: NWEndpoint.Port

        if let URLPort = url.port, let nwPort = NWEndpoint.Port(rawValue: UInt16(URLPort)) {
            port = url.scheme == "https" ? .https : .http
        } else {
            port = url.scheme == "https" ? .https : .http
        }

        let endpoint = NWEndpoint.hostPort(host: .init(url.host!), port: port)

        let parameters: NWParameters
        if url.scheme == "https" {
            parameters = NWParameters(tls: .init())
        } else {
            parameters = NWParameters(tls: nil)
        }

        parameters.requiredInterfaceType = .cellular
        parameters.prohibitedInterfaceTypes = [.wifi, .wiredEthernet, .loopback]

        if let protocolOption = parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
            protocolOption.version = ipVersion
        }

        connection = NWConnection(to: endpoint, using: parameters)
    }

    private func sendRequest(_ request: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Convert the request string to data and send it
        let requestData = Data(request.utf8)
        connection?.send(content: requestData, completion: .contentProcessed { error in
            if let error = error {
                completion(.failure(error))
            } else {
                self.receiveResponse(responseData: .init(), completion: completion)
            }
        })
    }

    private func receiveResponse(
        responseData: Data,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Receive the response data
        var responseData = responseData
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 40000) { data, _, isComplete, error in
            if let data = data {
                responseData.append(data)
            }

            if isComplete {
                self.connection?.cancel()
                self.connection?.cancelCurrentEndpoint()
                self.connection = nil

                guard var response = String(data: responseData, encoding: .ascii) else {
                    completion(.failure(Errors.unknownResponse))
                    return
                }

                Logger.log(response, lineNumber: #line)

                if (response as NSString).range(of: "HTTP/").location == NSNotFound {
                    completion(.failure(Errors.cantFoundHTTPResponse))
                    return
                }

                let prefixLocation = (response as NSString).range(of: "HTTP/").location + 9

                let toReturnRange = NSRange(location: prefixLocation, length: 1)

                let urlResponseCode = (response as NSString).substring(with: toReturnRange)

                Logger.log("URL Response code: \(urlResponseCode)", lineNumber: #line)
//
//                if self.didConnect == false {
//                    completion(.success("REDIRECT:https://mi6.dnlsrv.com/m/trecv2/v1?&cipherSalt=bKP2eLmzcqez5iVZ&state=1&SKEY=aFhJymMXemByEl_yEIpE57kroWIchEOo_sVqmS_LABhPlDeJkfYy17wKUIJ-X53s8_euzQuNI0i4xIN95Vg3rQ82loZn07RzvQb6vGM5VtFRvogbMMJV-jhtk_PEoBj4a8SqN4UJ0NIjqsncPKc2rMreRjbh-bCIRVj3L2t9ug2vKvbFJ_3xBvm1iZTz1moy"))
//                    self.didConnect = true
//                    return
//                }

                if urlResponseCode == "3" {
                    do {
                        let URLPattern = #"http.?://\S+"#
                        let regex = try NSRegularExpression(pattern: URLPattern, options: [])
                        let match = regex.firstMatch(in: response, options: [], range: NSRange(location: 0, length: response.utf16.count))

                        if let match = match, let range = Range(match.range, in: response) {
                            let url = response[range]
                            response = "REDIRECT:" + url
                        } else {
                            Logger.log("Unable to match URL", lineNumber: #line)
                        }
                    } catch {
                        Logger.log("Error creating regular expression \(error.localizedDescription)", lineNumber: #line)
                    }

                    Logger.log("Link: \(response)", lineNumber: #line)
                }

                completion(.success(response))
            } else if let error = error {
                completion(.failure(error))
            } else {
                self.receiveResponse(
                    responseData: responseData,
                    completion: completion
                )
            }
        }
    }
}
