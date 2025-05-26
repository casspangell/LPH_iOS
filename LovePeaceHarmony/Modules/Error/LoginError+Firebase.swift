//
//  LoginError+Firebase.swift
//  LovePeaceHarmony
//
//  Updated for iOS 17 compatibility
//

import FirebaseAuth

// MARK: - AuthErrorCode Extension (avoiding redeclaration)
extension AuthErrorCode {
    static func from(_ error: Error) -> AuthErrorCode? {
        return AuthErrorCode(rawValue: (error as NSError).code)
    }
}

// MARK: - LoginError Firebase Integration
extension LoginError {
    static func fromFirebaseError(_ error: Error) -> LoginError {
        guard let errorCode = AuthErrorCode.from(error) else {
            return .unknown
        }
        
        switch errorCode {
        case .wrongPassword:
            return .wrongPassword
        case .userNotFound:
            return .userNotFound
        case .invalidEmail:
            return .invalidCredentials
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword
        case .tooManyRequests:
            return .tooManyAttempts
        case .networkError:
            return .networkError
        case .userDisabled:
            return .invalidCredentials
        case .accountExistsWithDifferentCredential:
            return .emailAlreadyInUse
        case .credentialAlreadyInUse:
            return .emailAlreadyInUse
        default:
            return .serverError
        }
    }
}
