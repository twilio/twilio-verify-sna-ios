import Foundation
import SNANetworking

public class TwilioVerifySNABuilder {
    public static func build(
        requestManager: RequestManagerProtocol = RequestManager(
            networkProvider: NetworkRequestProvider(
                cellularSession: CellularSession()
            )
        )
    ) -> TwilioVerifySNA {
        TwilioVerifySNASession(requestManager: requestManager)
    }
}
