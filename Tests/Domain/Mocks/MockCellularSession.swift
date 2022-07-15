
import XCTest
import SNANetworking

@testable import TwilioVerifySNA

class MockCellularSession: CellularSessionProtocol {
    func performGetRequest(_ url: URL) -> CellularSessionResult {
        let result = CellularSessionResult()
        result.status = .success
        result.result = ""

        return result
    }
}
