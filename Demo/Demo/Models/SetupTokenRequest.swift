import Foundation

struct SetUpTokenRequest {
    
    let customerID: String?
    
    var path: String {
        "/setup_tokens/"
    }

    var method: String {
        "POST"
    }
    
    var headers: [String: String] {
        ["Content-Type": "application/json"]
    }
    
    var body: Data? {
        let requestBody: [String: Any] = [
            "customer": [
                "id": customerID
            ],
            "payment_source": [
                "card": [
                    "experience_context": [
                        "return_url": "https://example.com/successUrl",
                        "cancel_url": "https://example.com/cancelUrl"
                    ],
                    "verification_method": "SCA_ALWAYS"
                ] as [String: Any]
            ]
        ]

        return try? JSONSerialization.data(withJSONObject: requestBody)
    }
}
