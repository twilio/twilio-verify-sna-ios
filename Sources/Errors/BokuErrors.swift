import Foundation

/**
 Probably will delete this one.
 */
enum BokuErrors: Int {
    case phoneIdFailed = -10
    case phoneIdFailed2 = -11
    case phoneIdFailed3 = -17
    case phoneIdFailed4 = -20
    case unsupportedCarrier = -30
    case unsupportedCarrierOrPotentialWifi = -31
    case potentialDualSim = -32
    case noHeader = -33
    case carrierSystemError = -34
    case carrierIdentifiedInvalidPhoneNumber = -40

    var description: String {
        switch self {
            case .phoneIdFailed:
                return "Boku detected an generic error and PNV failed"

            case .phoneIdFailed2:
                return "Boku detected an Invalid condition and hence PNV failes"

            case .phoneIdFailed3:
                return "Boku detected an error in the PNV flow and hence PNV failed"

            case .phoneIdFailed4:
                return "Boku deteted an error in the EVURL and hence PNV failed"

            case .unsupportedCarrier:
                return "The identified carrier is unsupported for PN"

            case .unsupportedCarrierOrPotentialWifi:
                return "Boku is unable to identify the carrier from the detected IP."

            case .potentialDualSim:
                return """
Boku has detected that the transaction may be from a dual sim device where the carrier identified via IP does nto match the carrier identified via the phone number
"""
            case .noHeader:
                return "The carrier did not insert the header during the PNV flow hence Boku cannot verify the number"

            case .carrierSystemError:
                return "There was an error on the carrier system during the PNV flow"

            case .carrierIdentifiedInvalidPhoneNumber:
                return "Carrier is indication that the number is invalid. NO other authentication method will work"
        }
    }
}
