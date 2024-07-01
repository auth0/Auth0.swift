//
//  ContentView.swift
//  OAuth2Vision
//
//  Created by Desu Sai Venkat on 21/06/24.
//  Copyright © 2024 Auth0. All rights reserved.
//

import SwiftUI
import Auth0

struct ContentView: View {
    @State private var credentialsText = ""
    @State private var showCredentials = false
    @State private var actionFailedMessage = ""
    @State private var actionFailed = false
    @State private var isAuthenticated = false
    
    let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
    
    var body: some View {
        VStack {
            if isAuthenticated {
                Text("You are authenticated!")
                Button(action: logout) {
                    Text("Logout")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: getCredentials) {
                    Text("Show Credentials")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }.alert("Alert", isPresented: $showCredentials) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(credentialsText)
                }
            } else {
                Button(action: startAuthentication) {
                    Text("Authenticate")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }.alert("Failed to login", isPresented: $actionFailed) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(actionFailedMessage)
                }
            }
        }
        .padding()
    }
    
    private func startAuthentication() {
        Auth0
            .webAuth()
            .start { result in
                switch result {
                case .success(let credentials):
                    isAuthenticated = true
                    _ = credentialsManager.store(credentials: credentials)
                case .failure(let error):
                    actionFailed = true
                    actionFailedMessage = "Failed with: \(error)"
                }
            }
    }
    
    private func logout() {
        Auth0
            .webAuth()
            .clearSession { result in
                switch result {
                case .success:
                    isAuthenticated = false
                    print("Logged out")
                case .failure(let error):
                    print("Failed with: \(error)")
                }
            }
    }
    
    private func getCredentials() {
        credentialsManager.credentials { result in
            switch result {
            case .success(let credentials):
                showCredentials = true
                credentialsText = "Obtained credentials: \(credentials)"
            case .failure(let error):
                print("Failed with: \(error)")
            }
        }
    }
}
