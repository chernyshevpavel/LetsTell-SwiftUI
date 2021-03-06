//
//  AuthInteractor.swift
//  LetsTell
//
//  Created by Павел Чернышев on 12.03.2021.
//  Copyright (c) 2021 ___ORGANIZATIONNAME___. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import SwiftUI

protocol AuthBusinessLogic {
    func login(request: Auth.Login.Request)
    func loginBySavedToken(request: Auth.LoginByToken.Request)
}

protocol AuthDataStore {
    var requestFactory: RequestFactory { get set }
}

class AuthInteractor: AuthBusinessLogic, AuthDataStore {
    var requestFactory: RequestFactory
    var tokenStorage: TokenStorage
    var ownerStorage: OwnerStorage
    var tokenCheker: TockenCheckerProtocol
    var tokenRefresher: TokenRefresherProtocol
    
    var presenter: AuthPresentationLogic?
    
    init(
        factory: RequestFactory,
        tokenStorage: TokenStorage,
        ownerStorage: OwnerStorage,
        tokenCheker: TockenCheckerProtocol,
        tokenRefresher: TokenRefresherProtocol
    ) {
        self.requestFactory = factory
        self.tokenStorage = tokenStorage
        self.ownerStorage = ownerStorage
        self.tokenCheker = tokenCheker
        self.tokenRefresher = tokenRefresher
    }
    
    func login(request: Auth.Login.Request) {
        let errorParser = ErrorParserState<ErrorList>()
        let authRequestFactory = requestFactory.makeAuthRequestFactory(errorParser: errorParser)
        authRequestFactory.login(email: request.login, password: request.password) { [weak self] (response) in
            guard let self = self else {
                return
            }
            switch response.result {
            case .success(let loginResult):
                var authResponse = Auth.Login.Response(succes: loginResult.status == "ok")
                if !self.tokenStorage.setToken(Token(
                                                accessToken: loginResult.body.accessToken,
                                                tokenType: loginResult.body.tokenType,
                                                expiresIn: loginResult.body.expiresIn + Int(NSDate().timeIntervalSince1970))) {
                    authResponse.succes = false
                    authResponse.error = ErrorList(status: "error", errors: [
                        "Couldn't save the token".localizedLowercase
                    ])
                }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    if !self.ownerStorage.updateOwner(loginResult.body.user) {
                        print("Couldn't save ")
                    }
                }
                guard let presenter = self.presenter else {
                    return
                }
                presenter.presentLogin(response: authResponse)
            case .failure(let error):
                guard let presenter = self.presenter else {
                    return
                }
                if let parsedError = errorParser.parsedError {
                    presenter.presentLogin(response: Auth.Login.Response(succes: false, error: parsedError))
                } else {
                    presenter.presentLogin(response: Auth.Login.Response(succes: false, error: error))
                }
            }
        }
    }
    
    func loginBySavedToken(request: Auth.LoginByToken.Request) {
        guard let presenter = presenter else {
            fatalError("Can't work without presenter")
        }
        
        requestFactory.sessionQueue = DispatchQueue.global(qos: .userInitiated)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let tokenExist = self.tokenCheker.isExist()
            let tokenAlive = self.tokenCheker.isAlive()
            guard tokenExist, tokenAlive else {
                request.completion(false)
                return
            }
            
            self.tokenRefresher.refresh { valid in
                if valid {
                    presenter.presentLogin(response: Auth.Login.Response(succes: true))
                }
                request.completion(valid)
            }
        }
    }
}
