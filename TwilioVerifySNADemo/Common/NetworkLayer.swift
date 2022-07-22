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
        guard let url = URL(string: url) else {
            return onComplete(nil)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try? JSONEncoder().encode(request)

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
