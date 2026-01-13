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

    var phoneEnrollmentChallengeWithRecoveryCode: Data {
        return """
            {
             "authenticator_type" : "oob",
             "recovery_codes" : [
              "G14KWJB572GUSD2T3NJV625L"
             ],
             "oob_channel" : "sms",
             "oob_code" : "Fe26.2*SERVER_1767928705*daa9fa2ffcba664cb93f89206cfc54723a0b5519c9ecda29298a6df21adf4004*M41PongaBqP2XZJTn8sUVQ*mwLS8id8uwaqNyHA_JVHNVrNnzeoWTCKXx111mw771EhvKeqh2A_pn6a6__D4frkELpahaioDomAeRs9Hmmx9_ZblTXdylNzDS-RSCwKtGUj6py2ZlcShIJcDNJSYXiQwb-9j7GgS0DbTyNiqRiSm--CZK_RvR68D8RdcQGMhib64vmXzCM92q_SUVDbhyvDmFi9m2_RioWpa8EahpAbXmf-AwP4mBLIZkslMOjfu8j5OMgCt3KYLyhT4zC_4kA-y3FptIHrrRnqAB3SQoJXJzi4Cu2CxWIZ_sydIPZUm7MI2YfHYOQLMSC5oGGNIVWSmG3pU4Vwxmg8-GIO0FQ2TeBzOF1lm4I1-ITSeLMBsXy6HrglyLsppa56tCHKqBVV*1768202403647*8c706fc66eb5cc3481ab2d351aafb2d15be9ac44c509d593bea0c4aa86bd515a*6kDRUDe5YrFkX1kstD2hZC2f4tMS8mT_LO9cjhNnNRY",
             "binding_method" : "prompt"
            }            
            """.data(using: .utf8)!
    }
    
    var phoneEnrollmentChallengeWithoutRecoveryCode: Data {
        return """
            {
             "authenticator_type" : "oob",
             "oob_channel" : "sms",
             "oob_code" : "Fe26.2*SERVER_1767928705*daa9fa2ffcba664cb93f89206cfc54723a0b5519c9ecda29298a6df21adf4004*M41PongaBqP2XZJTn8sUVQ*mwLS8id8uwaqNyHA_JVHNVrNnzeoWTCKXx111mw771EhvKeqh2A_pn6a6__D4frkELpahaioDomAeRs9Hmmx9_ZblTXdylNzDS-RSCwKtGUj6py2ZlcShIJcDNJSYXiQwb-9j7GgS0DbTyNiqRiSm--CZK_RvR68D8RdcQGMhib64vmXzCM92q_SUVDbhyvDmFi9m2_RioWpa8EahpAbXmf-AwP4mBLIZkslMOjfu8j5OMgCt3KYLyhT4zC_4kA-y3FptIHrrRnqAB3SQoJXJzi4Cu2CxWIZ_sydIPZUm7MI2YfHYOQLMSC5oGGNIVWSmG3pU4Vwxmg8-GIO0FQ2TeBzOF1lm4I1-ITSeLMBsXy6HrglyLsppa56tCHKqBVV*1768202403647*8c706fc66eb5cc3481ab2d351aafb2d15be9ac44c509d593bea0c4aa86bd515a*6kDRUDe5YrFkX1kstD2hZC2f4tMS8mT_LO9cjhNnNRY",
             "binding_method" : "prompt"
            }            
            """.data(using: .utf8)!
    }

    var challengeData: Data {
        return """
        {
         "challenge_type" : "oob",
         "oob_code" : "Fe26.2*SERVER_1767928705*c07b491097a63f380a635dcd122f3191e10a671f8a136e53d261d3a99e53abc1*YVe_7o7SbFNURbjXSQzTEg*1BDWU0i-IO1kE_WRLjHcXQhszHgoQcVKsHAniyWMnOaUwRxTc5uKlfoWz2poYwS2cwFPbf868KFmAshTlXlytlQe4uGvLBkwjwdAYL8VL2BwV9e2rDtoqBCAgP4qESzLiNWuN8vRN_eddsG7mrfmEkz3t_k7LNYTHLIkyC1zgTLww4QVbsHwHGL3TvBu1U3xvzMQ_Abv3xbnLtIrWcZbMzxe-JXRQ5Fw9-pD5zx6-2xeU3zcBzUQ2SQSC_cs5fuwzUzKm7TiMAE2kGV_EJ_8UmAoc6yPnRAvudm2kNvY_G6jfuzriqsV8mhfJVrCKM8dQGwwnMye1Nqe9tavMs9Tk7bm6KEjEAYk7x6CepdIeVajtlpjlef_Mwwn02nuK_pC*1768216113061*a7b60435bf02e470f56767477678fb852edb9c032d8e1528f64b003078286a11*tfFIO4_1BFvlNdzs5s7mKjW6ajvrlkBF7HUrGur9VIk",
         "binding_method" : "prompt"
        }
        """.data(using: .utf8)!
    }

    var authenticatorsData: Data {
        return """
            [
             {
              "authenticator_type" : "oob",
              "id" : "sms|dev_WNScJzYAmuV1enCR",
              "active" : true,
              "oob_channel" : "sms",
              "name" : "XXXXXXXXX2046"
             },
             {
              "authenticator_type" : "oob",
              "id" : "voice|dev_WNScJzYAmuV1enCR",
              "active" : true,
              "oob_channel" : "voice",
              "name" : "XXXXXXXXX2046"
             },
             {
              "id" : "recovery-code|dev_ZdXKDYctdGHWWAN5",
              "authenticator_type" : "recovery-code",
              "active" : true
             },
             {
              "authenticator_type" : "oob",
              "id" : "email|dev_6fOgD5yp5UMV52Ns",
              "active" : true,
              "oob_channel" : "email",
              "name" : "example******@gmai*****"
             }
            ]
            """.data(using: .utf8)!
    }
    
    @Test
    func testGetAuthenticatorsSuccess() async {
        do {
            let request = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).getAuthenticators(mfaToken: "", factorsAllowed: [])
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { request in
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, self.authenticatorsData)
                }
                
                let authenticators = try await request.start()
                #expect(authenticators.count == 4)
            }
        } catch {
        }
    }
    
    @Test
    func testEnrollPhoneWithRecoveryCodes() async {
        do {
            let request = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).enroll(mfaToken: "", phoneNumber: "")
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { request in
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, phoneEnrollmentChallengeWithRecoveryCode)
                }
                let phoneChallenge = try await request.start()
                #expect(phoneChallenge.recoveryCodes?.first == "G14KWJB572GUSD2T3NJV625L")
            }
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func testEnrollPhoneWithoutRecoveryCodes() async {
        do {
            let request = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).enroll(mfaToken: "", phoneNumber: "")
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { request in
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, phoneEnrollmentChallengeWithoutRecoveryCode)
                }
                let phoneChallenge = try await request.start()
                #expect(phoneChallenge.recoveryCodes == nil)
            }
        } catch {
            Issue.record(error)
        }
    }
    
    @Test
    func testMFAChallenge() async  {
        do {
            let request = Auth0.mfa(clientId: "", domain: "", session: makeMockSession()).challenge(with: "", mfaToken: "")
            try await confirmation(expectedCount: 1) { confirmation in
                MockURLProtocol.requestHandler = { request in
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    confirmation()
                    return (response, challengeData)
                }
                let phoneChallenge = try await request.start()
                #expect(phoneChallenge.oobCode == "Fe26.2*SERVER_1767928705*c07b491097a63f380a635dcd122f3191e10a671f8a136e53d261d3a99e53abc1*YVe_7o7SbFNURbjXSQzTEg*1BDWU0i-IO1kE_WRLjHcXQhszHgoQcVKsHAniyWMnOaUwRxTc5uKlfoWz2poYwS2cwFPbf868KFmAshTlXlytlQe4uGvLBkwjwdAYL8VL2BwV9e2rDtoqBCAgP4qESzLiNWuN8vRN_eddsG7mrfmEkz3t_k7LNYTHLIkyC1zgTLww4QVbsHwHGL3TvBu1U3xvzMQ_Abv3xbnLtIrWcZbMzxe-JXRQ5Fw9-pD5zx6-2xeU3zcBzUQ2SQSC_cs5fuwzUzKm7TiMAE2kGV_EJ_8UmAoc6yPnRAvudm2kNvY_G6jfuzriqsV8mhfJVrCKM8dQGwwnMye1Nqe9tavMs9Tk7bm6KEjEAYk7x6CepdIeVajtlpjlef_Mwwn02nuK_pC*1768216113061*a7b60435bf02e470f56767477678fb852edb9c032d8e1528f64b003078286a11*tfFIO4_1BFvlNdzs5s7mKjW6ajvrlkBF7HUrGur9VIk")
            }
        } catch {
            Issue.record(error)
        }
    }
}
