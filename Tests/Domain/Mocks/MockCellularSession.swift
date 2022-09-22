
import XCTest
import SNANetworking

@testable import TwilioVerifySNA

class MockCellularSession: CellularSessionProtocol {
    let status: CellularSessionStatus

    init(status: CellularSessionStatus = .success) {
        self.status = status
    }

    func performRequest(_ url: URL) -> CellularSessionResult {
        let result = CellularSessionResult()
        result.status = status
        result.result = String(describing: status)

        return result
    }
}
