//
//  LoginValidationError.swift
//  LovePeaceHarmony
//
//  Created by Aghil C M on 29/11/17.
//  Copyright © 2017 LovePeaceHarmony. All rights reserved.
//

public enum LoginValidationError: Int, Error {
    case emptyName
    case emptyEmail
    case invalidEmail
    case emptyPassword
    case passwordLength
    case emptyConfirmPassword
    case passwordDoNotMatch
    case invalidCredentials
    
    var localizedDescription: String {
        switch self {
        case .emptyName:
            return NSLocalizedString("Please enter your name", comment: "")
        case .emptyEmail:
            return NSLocalizedString("Please enter your email", comment: "")
        case .invalidEmail:
            return NSLocalizedString("Please enter a valid email address", comment: "")
        case .emptyPassword:
            return NSLocalizedString("Please enter your password", comment: "")
        case .passwordLength:
            return NSLocalizedString("Password must be at least 6 characters long", comment: "")
        case .emptyConfirmPassword:
            return NSLocalizedString("Please confirm your password", comment: "")
        case .passwordDoNotMatch:
            return NSLocalizedString("Passwords do not match", comment: "")
        case .invalidCredentials:
            return NSLocalizedString("Invalid email or password", comment: "")
        }
    }
} 