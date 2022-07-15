import XCTest
import SNANetworking

@testable import TwilioVerifySNA

struct MockNetworkRequestProvider: NetworkRequestProviderProtocol {

    private let session: CellularSessionProtocol = MockCellularSession()

    func performRequest(url: URL, onComplete: @escaping NetworkRequestResult) {
        let request = session.performGetRequest(url)

        guard let result = request.result else {
            return onComplete(.failure(.requestFinishedWithNoResult))
        }

        onComplete(.success(result))
    }
}
