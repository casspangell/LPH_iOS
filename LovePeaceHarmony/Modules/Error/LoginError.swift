import Foundation

public enum LoginError: Int, Error {
    case networkError
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case userNotFound
    case wrongPassword
    case tooManyAttempts
    case serverError
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .networkError:
            return NSLocalizedString("Network error. Please check your connection.", comment: "")
        case .invalidCredentials:
            return NSLocalizedString("Invalid email or password.", comment: "")
        case .emailAlreadyInUse:
            return NSLocalizedString("This email is already registered. Please try logging in.", comment: "")
        case .weakPassword:
            return NSLocalizedString("Password is too weak. Please use a stronger password.", comment: "")
        case .userNotFound:
            return NSLocalizedString("No account found with this email.", comment: "")
        case .wrongPassword:
            return NSLocalizedString("Incorrect password.", comment: "")
        case .tooManyAttempts:
            return NSLocalizedString("Too many failed attempts. Please try again later.", comment: "")
        case .serverError:
            return NSLocalizedString("Server error. Please try again later.", comment: "")
        case .unknown:
            return NSLocalizedString("An unknown error occurred.", comment: "")
        }
    }
    
    static func fromNetworkError(_ error: Error) -> LoginError {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                return .invalidCredentials
            case .custom(let message):
                if message.contains("email already exists") {
                    return .emailAlreadyInUse
                } else if message.contains("user not found") {
                    return .userNotFound
                }
                return .networkError
            default:
                return .networkError
            }
        }
        return .unknown
    }
} 