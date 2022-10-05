import Foundation

struct VerificationRequest: Encodable {
    let phoneNumber: String
}

struct VerificationResponse: Decodable {
    let snaUrl: String
}

struct VerificationResult: Decodable {
    let success: Bool
}
