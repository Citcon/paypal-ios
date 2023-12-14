import Foundation
import CorePayments

/// API Client used to create and process orders on sample merchant server
final class DemoMerchantAPI {

    // MARK: Public properties

    static let sharedService = DemoMerchantAPI()

    // To hardcode an order ID and client ID for this demo app, set the below values
    enum InjectedValues {
        static let orderID: String? = nil
        static let clientID: String? = nil
    }

    private init() {}

    // MARK: Public Methods

    func getSetupToken(
        customerID: String? = nil,
        selectedMerchantIntegration: MerchantIntegration,
        paymentSourceType: PaymentSourceType
    ) async throws -> SetUpTokenResponse {
        do {
            // TODO: pass in headers depending on integration type
            // Different request struct or integration type property
            // in SetUpTokenRequest to conditionally add header
            let request = SetUpTokenRequest(customerID: customerID, paymentSource: paymentSourceType)
            var assertionHeader: String?
            if selectedMerchantIntegration == .connectedPath4 {
                assertionHeader = try await fetchAssertionHeader()
            }

            let urlRequest = try createSetupTokenUrlRequest(
                setupTokenRequest: request,
                environment: DemoSettings.environment,
                selectedMerchantIntegration: selectedMerchantIntegration,
                assertionHeader: assertionHeader
            )
            
            let data = try await data(for: urlRequest)
            return try parse(from: data)
        } catch {
            print("error with the create setup token request: \(error.localizedDescription)")
            throw error
        }
    }

    func getPaymentToken(setupToken: String, selectedMerchantIntegration: MerchantIntegration) async throws -> PaymentTokenResponse {
        do {
            let request = PaymentTokenRequest(setupToken: setupToken)
            var assertionHeader: String?
            // toggle with CP3
            if selectedMerchantIntegration == .connectedPath4 {
                assertionHeader = try await fetchAssertionHeader()
            }
            let urlRequest = try createPaymentTokenUrlRequest(
                paymentTokenRequest: request,
                environment: DemoSettings.environment,
                selectedMerchantIntegration: selectedMerchantIntegration,
                assertionHeader: assertionHeader
            )
            let data = try await data(for: urlRequest)
            return try parse(from: data)
        } catch {
            print("error with the create payment token request: \(error.localizedDescription)")
            throw error
        }
    }

    func completeOrder(intent: Intent, orderID: String) async throws -> Order {
        let intent = intent == .authorize ? "authorize" : "capture"
        guard let url = buildBaseURL(
            with: "/orders/\(orderID)/\(intent)",
            selectedMerchantIntegration: DemoSettings.merchantIntegration
        ) else {
            throw URLResponseError.invalidURL
        }

        var assertionHeader: String?
        if DemoSettings.merchantIntegration == .connectedPath4 {
            assertionHeader = try await fetchAssertionHeader()
        }

        let urlRequest = buildURLRequest(method: "POST", url: url, body: EmptyBodyParams(), assertionHeader: assertionHeader)
        let data = try await data(for: urlRequest)
        return try parse(from: data)
    }

    func captureOrder(orderID: String, selectedMerchantIntegration: MerchantIntegration) async throws -> Order {
        guard let url = buildBaseURL(with: "/orders/\(orderID)/capture", selectedMerchantIntegration: selectedMerchantIntegration) else {
            throw URLResponseError.invalidURL
        }
        
        var assertionHeader: String?
        if DemoSettings.merchantIntegration == .connectedPath4 {
            assertionHeader = try await fetchAssertionHeader()
        }

        let urlRequest = buildURLRequest(method: "POST", url: url, body: EmptyBodyParams(), assertionHeader: assertionHeader)
        let data = try await data(for: urlRequest)
        return try parse(from: data)
    }
    
    func authorizeOrder(orderID: String, selectedMerchantIntegration: MerchantIntegration) async throws -> Order {
        guard let url = buildBaseURL(with: "/orders/\(orderID)/authorize", selectedMerchantIntegration: selectedMerchantIntegration) else {
            throw URLResponseError.invalidURL
        }

        var assertionHeader: String?
        if DemoSettings.merchantIntegration == .connectedPath4 {
            assertionHeader = try await fetchAssertionHeader()
        }

        let urlRequest = buildURLRequest(method: "POST", url: url, body: EmptyBodyParams(), assertionHeader: assertionHeader)
        let data = try await data(for: urlRequest)
        return try parse(from: data)
    }
    
    /// This function replicates a way a merchant may go about creating an order on their server and is not part of the SDK flow.
    /// - Parameter orderParams: the parameters to create the order with
    /// - Returns: an order
    /// - Throws: an error explaining why create order failed
    func createOrder(orderParams: CreateOrderParams, selectedMerchantIntegration: MerchantIntegration) async throws -> Order {
        if let injectedOrderID = InjectedValues.orderID {
            return Order(id: injectedOrderID, status: "CREATED")
        }
        guard let url = buildBaseURL(with: "/orders", selectedMerchantIntegration: selectedMerchantIntegration) else {
            throw URLResponseError.invalidURL
        }

        var assertionHeader: String?
        // toggle with CP3
        if selectedMerchantIntegration == .connectedPath4 {
            assertionHeader = try await fetchAssertionHeader()
        }
        let urlRequest = buildURLRequest(method: "POST", url: url, body: orderParams, assertionHeader: assertionHeader)

        let data = try await data(for: urlRequest)
        return try parse(from: data)
    }

    func fetchAssertionHeader() async throws -> String? {
        let merchantID = "RVUPSJV3CJXZ6"
        var clientID: String?
        var assertionHeader: String?

        clientID = await fetchClientID(environment: DemoSettings.environment, selectedMerchantIntegration: DemoSettings.merchantIntegration)
        guard let clientID else {
            return nil
        }
        let headerDict = ["alg": "none"]
        let payloadDict = ["payer_id": merchantID, "iss": clientID ]

        let headerData = try? JSONSerialization.data(withJSONObject: headerDict)
        let payloadData = try? JSONSerialization.data(withJSONObject: payloadDict)

        guard let headerData, let payloadData else {
            return nil
        }

        let headerBase64 = headerData.base64EncodedString()
        let payloadBase64 = payloadData.base64EncodedString()

        assertionHeader = "\(headerBase64).\(payloadBase64)."
        return assertionHeader
    }

    /// This function replicates a way a merchant may go about patching an order on their server and is not part of the SDK flow.
    /// - Parameters:
    ///   - updateOrderParams: the parameters to update the order with
    /// - Throws: an error explaining why patching the order failed
    func updateOrder(_ updateOrderParams: UpdateOrderParams, selectedMerchantIntegration: MerchantIntegration) async throws {
        guard let url = buildBaseURL(
            with: "/orders/" + updateOrderParams.orderID, selectedMerchantIntegration: selectedMerchantIntegration
        ) else {
            throw URLResponseError.invalidURL
        }
        let urlRequest = buildURLRequest(method: "PATCH", url: url, body: updateOrderParams.updateOperations)
        _ = try await data(for: urlRequest)
    }

    /// This function fetches a clientID to initialize any module of the SDK
    /// - Parameters:
    ///   - environment: the current environment
    /// - Returns: a String representing an clientID
    /// - Throws: an error explaining why fetch clientID failed
    public func getClientID(environment: Demo.Environment, selectedMerchantIntegration: MerchantIntegration) async -> String? {
        if let injectedClientID = InjectedValues.clientID {
            return injectedClientID
        }
        
        let clientID = await fetchClientID(environment: environment, selectedMerchantIntegration: selectedMerchantIntegration)
            return clientID
    }

    // MARK: Private methods

    private func buildURLRequest<T>(method: String, url: URL, body: T, assertionHeader: String? = nil) -> URLRequest where T: Encodable {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let assertionHeader {
            urlRequest.addValue("\(assertionHeader)", forHTTPHeaderField: "PayPal-Auth-Assertion")
        }

        if let json = try? encoder.encode(body) {
            print(String(data: json, encoding: .utf8) ?? "")
            urlRequest.httpBody = json
        }

        return urlRequest
    }

    private func data(for urlRequest: URLRequest) async throws -> Data {
        do {
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            return data
        } catch {
            throw URLResponseError.networkConnectionError
        }
    }

    private func parse<T: Decodable>(from data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            throw URLResponseError.dataParsingError
        }
    }

    private func buildBaseURL(with endpoint: String, selectedMerchantIntegration: MerchantIntegration = .direct) -> URL? {
        return URL(string: DemoSettings.environment.baseURL + selectedMerchantIntegration.path + endpoint)
    }

    private func buildPayPalURL(with endpoint: String) -> URL? {
        URL(string: "https://api.sandbox.paypal.com" + endpoint)
    }

    private func fetchClientID(environment: Demo.Environment, selectedMerchantIntegration: MerchantIntegration) async -> String? {
        do {
            let clientIDRequest = ClientIDRequest()
            let request = try createUrlRequest(
                clientIDRequest: clientIDRequest, environment: environment, selectedMerchantIntegration: selectedMerchantIntegration
            )
            let (data, response) = try await URLSession.shared.performRequest(with: request)
            guard let response = response as? HTTPURLResponse else {
                throw URLResponseError.serverError
            }
            switch response.statusCode {
            case 200..<300:
                let clientIDResponse: ClientIDResponse = try parse(from: data)
                return clientIDResponse.clientID
            default: throw URLResponseError.dataParsingError
            }
        } catch {
            print("Error in fetching clientID")
            return nil
        }
    }
    
    private func createUrlRequest(
        clientIDRequest: ClientIDRequest,
        environment: Demo.Environment,
        selectedMerchantIntegration: MerchantIntegration
    ) throws -> URLRequest {
        var completeUrl = environment.baseURL
       
        completeUrl += selectedMerchantIntegration.path
        completeUrl.append(contentsOf: clientIDRequest.path)
        guard let url = URL(string: completeUrl) else {
            throw URLResponseError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = clientIDRequest.method.rawValue
        request.httpBody = clientIDRequest.body
        clientIDRequest.headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key.rawValue)
        }
        return request
    }
    
    private func createSetupTokenUrlRequest(
        setupTokenRequest: SetUpTokenRequest,
        environment: Demo.Environment,
        selectedMerchantIntegration: MerchantIntegration,
        assertionHeader: String? = nil
    ) throws -> URLRequest {
        var completeUrl = environment.baseURL
        completeUrl += selectedMerchantIntegration.path
        completeUrl.append(contentsOf: setupTokenRequest.path)

        guard let url = URL(string: completeUrl) else {
            throw URLResponseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = setupTokenRequest.method
        request.httpBody = setupTokenRequest.body
        setupTokenRequest.headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        if let assertionHeader {
            request.addValue("\(assertionHeader)", forHTTPHeaderField: "PayPal-Auth-Assertion")
        }

        return request
    }
    
    private func createPaymentTokenUrlRequest(
        paymentTokenRequest: PaymentTokenRequest,
        environment: Demo.Environment,
        selectedMerchantIntegration: MerchantIntegration,
        assertionHeader: String? = nil
    ) throws -> URLRequest {
        var completeUrl = environment.baseURL
        completeUrl += selectedMerchantIntegration.path
        completeUrl.append(contentsOf: paymentTokenRequest.path)

        guard let url = URL(string: completeUrl) else {
            throw URLResponseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = paymentTokenRequest.method
        request.httpBody = paymentTokenRequest.body
        paymentTokenRequest.headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }

        if let assertionHeader {
            request.addValue("\(assertionHeader)", forHTTPHeaderField: "PayPal-Auth-Assertion")
        }

        return request
    }
}
