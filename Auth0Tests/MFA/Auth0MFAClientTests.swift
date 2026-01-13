import Testing
import Foundation
@testable import Auth0

@Suite(.serialized)
struct Auth0MFAClientTests {
    private let mockToken = "mock_access_token_123"
    private let mockDomain = "test-tenant.auth0.com"
    private func makeMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    func decodeResponse<T: Decodable>(json: Data, locationHeader: String? = nil) throws -> T {
        let decoder = JSONDecoder()
        decoder.userInfo[CodingUserInfoKey(rawValue: "locationHeader")!] = locationHeader
        return try decoder.decode(T.self, from: json)
    }
   
    var enrollData: Data {
        let response = """
                        
            """.data(using: .utf8)!
        return response
    }
    
    var challengeData: Data {
        let response = """
        
        """.data(using: .utf8)!
        return response
    }
    
    var factorsData: Data {
        let factors = """
            {
            "factors": [
            {
             "type" : "phone",
             "usage" : [
              "secondary"
             ]
            },
            {
             "type" : "push-notification",
             "usage" : [
              "secondary"
             ]
            },
            {
             "type" : "totp",
             "usage" : [
              "secondary"
             ]
            },
            {
             "type" : "email",
             "usage" : [
              "secondary"
             ]
            },
            {
             "type" : "recovery-code",
             "usage" : [
              "secondary"
             ]
            }
            ]}
            """.data(using: .utf8)!
        return factors
    }
    
    var authMethods: [AuthenticationMethod] {
        do {
            let authMethods: AuthenticationMethods = try decodeResponse(json: authMethodsData)
            return authMethods.authenticationMethods
        } catch {
            return []
        }
    }

    var factors: [Factor] {
        do {
            let factors: Factors = try decodeResponse(json: factorsData)
            return factors.factors
        } catch {
            return []
        }
    }


    @Test
    func testInitialState() async {
        Auth0UIComponentsSDKInitializer.reset()
        Auth0UIComponentsSDKInitializer.initialize(session: makeMockSession(), bundle: .main, domain: mockDomain, clientId: "", audience: "\(mockDomain)/me/", tokenProvider: MockTokenProvider())
        let viewModel = await MyAccountAuthMethodsViewModel()
        await MainActor.run {
            #expect(viewModel.errorViewModel == nil)
            #expect(viewModel.viewComponents.isEmpty)
        }
    }
    
    @Test
    func testFetchingOfAuthMethodsSuccess() async {
        let mockTokenProvider = MockTokenProvider()
        Auth0UIComponentsSDKInitializer.reset()
        Auth0UIComponentsSDKInitializer.initialize(session: makeMockSession(), bundle: .main, domain: mockDomain, clientId: "", audience: "\(mockDomain)/me/", tokenProvider: mockTokenProvider)

        let viewModel = await MyAccountAuthMethodsViewModel(factorsUseCase: GetFactorsUseCase(session: makeMockSession()), authMethodsUseCase: GetAuthMethodsUseCase(session: makeMockSession()))
        await confirmation(expectedCount: 2) { @MainActor confirmation in
            MockURLProtocol.requestHandler = { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                if request.url?.absoluteString.contains("factors") == true {
                    confirmation()
                    return (response, factorsData)
                } else {
                    confirmation()
                    return (response, authMethodsData)
                }
            }
            await viewModel.loadMyAccountAuthViewComponentData()
            #expect(viewModel.viewComponents.count == 7)
        }
    }
}
