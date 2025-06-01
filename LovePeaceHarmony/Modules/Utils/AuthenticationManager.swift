import Foundation

class AuthenticationManager {
    static let shared = AuthenticationManager()
    private let tokenService = "com.lovepeaceharmony.auth"
    private let tokenAccount = "userToken"
    private(set) var isLoggedIn: Bool = false
    private(set) var isLoading: Bool = false

    var token: String? {
        get {
            guard let data = KeychainHelper.shared.read(service: tokenService, account: tokenAccount) else { return nil }
            return String(data: data, encoding: .utf8)
        }
        set {
            if let token = newValue {
                let data = Data(token.utf8)
                KeychainHelper.shared.save(data, service: tokenService, account: tokenAccount)
            } else {
                KeychainHelper.shared.delete(service: tokenService, account: tokenAccount)
            }
        }
    }

    func autoLogin(completion: @escaping (Bool) -> Void) {
        isLoading = true
        guard let token = token else {
            isLoading = false
            completion(false)
            return
        }
        validateSession(token: token) { [weak self] isValid, needsRefresh in
            guard let self = self else { return }
            if isValid {
                self.isLoggedIn = true
                self.isLoading = false
                completion(true)
            } else if needsRefresh {
                self.refreshToken { refreshed in
                    self.isLoggedIn = refreshed
                    self.isLoading = false
                    completion(refreshed)
                }
            } else {
                self.logout()
                self.isLoading = false
                completion(false)
            }
        }
    }

    func login(withToken token: String) {
        self.token = token
        self.isLoggedIn = true
    }

    func logout() {
        self.token = nil
        self.isLoggedIn = false
    }

    // MARK: - Session Validation

    private func validateSession(token: String, completion: @escaping (Bool, Bool) -> Void) {
        // Replace with your backend API call
        let url = URL(string: "https://yourapi.com/validate-session")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(true, false)
                } else if httpResponse.statusCode == 401 {
                    completion(false, true)
                } else {
                    completion(false, false)
                }
            } else {
                completion(false, false)
            }
        }.resume()
    }

    private func refreshToken(completion: @escaping (Bool) -> Void) {
        // Replace with your backend API call for token refresh
        completion(false) // For demo, always fail
    }
} 