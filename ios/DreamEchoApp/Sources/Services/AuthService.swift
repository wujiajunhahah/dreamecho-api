import Foundation

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var session: UserSession?
    private let apiClient: APIClient

    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient()
    }

    func bootstrap() async {
        do {
            session = try await apiClient.fetchSession()
        } catch {
            session = nil
        }
    }

    func login(email: String, password: String) async throws {
        session = try await apiClient.login(email: email, password: password)
    }

    func register(username: String, email: String, password: String) async throws {
        session = try await apiClient.register(username: username, email: email, password: password)
    }

    func logout() async {
        await apiClient.logout()
        session = nil
    }

    func loginAsGuest() async throws {
        // 纯本地访客会话，便于演示，不依赖网络
        let guest = User(id: UUID(), username: "访客", email: "guest@local")
        session = UserSession(user: guest, token: "guest-token")
    }

    func loginWithApple(userIdentifier: String, email: String?) async {
        // Demo：直接本地建会话，避免服务器依赖
        let username = email ?? "Apple 用户"
        let user = User(id: UUID(), username: username, email: email ?? "apple@local")
        session = UserSession(user: user, token: "apple-")
    }
}

struct UserSession: Codable, Sendable {
    let user: User
    let token: String
    
    enum CodingKeys: String, CodingKey {
        case user
        case token
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        token = try container.decode(String.self, forKey: .token)
        user = try container.decode(User.self, forKey: .user)
    }
    
    init(user: User, token: String) {
        self.user = user
        self.token = token
    }
}
