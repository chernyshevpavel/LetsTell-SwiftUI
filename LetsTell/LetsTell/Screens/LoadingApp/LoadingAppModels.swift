//
//  LoadingAppModels.swift
//  LetsTell
//
//  Created by Павел Чернышев on 29.03.2021.
//  Copyright (c) 2021 ___ORGANIZATIONNAME___. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

enum LoadingApp {
  // MARK: Use cases
  
  enum CheckToken {
    struct Request {
        
    }
    struct Response {
        var exist: Bool
        var alive: Bool
        var valid: Bool
    }
    struct ViewModel {
        var success: Bool
    }
  }
}
