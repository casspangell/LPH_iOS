import Foundation

struct APIResponse<T: Codable>: Codable {
    let status: Bool
    let message: String?
    let data: T?
    let error: APIError?
    
    enum CodingKeys: String, CodingKey {
        case status = "success"
        case message
        case data
        case error
    }
}

struct APIError: Codable {
    let code: Int
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case code
        case message
    }
}

extension APIResponse {
    var isSuccess: Bool {
        return status && error == nil
    }
    
    func toResult() -> Swift.Result<T, NetworkError> {
        if isSuccess, let data = data {
            return .success(data)
        } else {
            let errorMessage = error?.message ?? message ?? "Unknown error"
            return .failure(.custom(errorMessage))
        }
    }
} 