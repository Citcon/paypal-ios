import Foundation
import CardPayments

struct CardVaultState: Equatable {

    struct UpdateSetupTokenResult: Decodable, Equatable {

        var id: String
        var status: String
    }

    var setupToken: SetUpTokenResponse?
    var updateSetupToken: UpdateSetupTokenResult?
    var paymentToken: PaymentTokenResponse?

    var setupTokenResponse: LoadingState<SetUpTokenResponse> = .idle {
        didSet {
            if case .loaded(let value) = setupTokenResponse {
                setupToken = value
            }
        }
    }

    var updateSetupTokenResponse: LoadingState<UpdateSetupTokenResult> = .idle {
        didSet {
            if case .loaded(let value) = updateSetupTokenResponse {
                updateSetupToken = value
            }
        }
    }

    var paymentTokenResponse: LoadingState<PaymentTokenResponse> = .idle {
        didSet {
            if case .loaded(let value) = paymentTokenResponse {
                paymentToken = value
            }
        }
    }
}

enum LoadingState<T: Decodable & Equatable>: Equatable {

    case idle
    case loading
    case error(message: String)
    case loaded(_ value: T)
}
