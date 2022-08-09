import XCTest
import SNANetworking

@testable import TwilioVerifySNA

struct MockRequestManager: RequestManagerProtocol {

    let shouldFail: Bool
    let expectedError: RequestManager.RequestError?

    func processSNAURL(
        _ url: String,
        onComplete: @escaping ProcessSNAURLResult
    ) {
        if shouldFail {
            let error =  (expectedError ?? .instanceNotFound)
            return onComplete(.failure(error))
        }

        let networkProvider = MockNetworkRequestProvider()

        networkProvider.performRequest(url: URL(string: url)!) { result in
            switch result {
                case .success:
                    onComplete(.success)
                case .failure(let error):
                    onComplete(.failure(.networkingError(cause: error)))
            }
        }
    }
}
