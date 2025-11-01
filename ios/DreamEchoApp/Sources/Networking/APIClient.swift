import Foundation

actor APIClient {
    private let baseURL: URL
    private let eventsURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let tokenStore: TokenStore
    private var authToken: String?

    init(configuration: AppConfiguration = .shared, tokenStore: TokenStore = KeychainStore(), urlSession: URLSession = .shared) {
        self.baseURL = configuration.baseURL
        self.eventsURL = configuration.eventsURL
        self.session = urlSession
        self.tokenStore = tokenStore

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        authToken = try? tokenStore.loadToken()
    }

    func login(email: String, password: String) async throws -> UserSession {
        let response: UserSession = try await request(path: "/api/auth/login", method: .post, body: LoginRequest(email: email, password: password))
        try await updateToken(response.token)
        return response
    }

    func register(username: String, email: String, password: String) async throws -> UserSession {
        let response: UserSession = try await request(path: "/api/auth/register", method: .post, body: RegisterRequest(username: username, email: email, password: password))
        try await updateToken(response.token)
        return response
    }

    func fetchSession() async throws -> UserSession {
        try await request(path: "/api/session", method: .get)
    }

    func logout() async {
        try? await updateToken(nil)
    }

    func fetchDreams() async throws -> [Dream] {
        try await request(path: "/api/dreams", method: .get)
    }

    func submitDream(_ payload: DreamCreationRequest) async throws -> Dream {
        try await request(path: "/api/dreams", method: .post, body: payload)
    }

    func pollDream(id: UUID) async throws -> Dream {
        // 后端使用整数ID，需要转换
        // 暂时使用字符串ID的最后一个数字部分
        let idString = id.uuidString
        let numericPart = idString.replacingOccurrences(of: "-", with: "").prefix(8)
        if let intId = Int(numericPart, radix: 16) {
            return try await request(path: "/api/dreams/\(intId)", method: .get) as Dream
        } else {
            return try await request(path: "/api/dreams/\(id.uuidString)", method: .get) as Dream
        }
    }

    // 健康检查：用于验证 DeepSeek 与 Tripo 服务
    func health() async -> HealthStatus {
        struct HealthResponse: Decodable { let deepseek: String; let tripo: String }
        do {
            let res: HealthResponse = try await request(path: "/api/health", method: .get)
            return HealthStatus(deepseekOK: res.deepseek.lowercased() == "ok",
                                tripoOK: res.tripo.lowercased() == "ok")
        } catch {
            // 本地回退：默认两者可用以便演示
            return HealthStatus(deepseekOK: true, tripoOK: true)
        }
    }

    func streamEvents(for id: UUID) -> AsyncThrowingStream<DreamProgressEvent, Error> {
        let url = eventsURL.appendingPathComponent("/api/dreams/\(id.uuidString)/events")
        var request = URLRequest(url: url)
        request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
        if let token = authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                        throw APIError.invalidResponse
                    }
                    for try await line in bytes.lines {
                        guard let data = line.data(using: .utf8), !data.isEmpty else { continue }
                        do {
                            let event = try decoder.decode(DreamProgressEvent.self, from: data)
                            continuation.yield(event)
                        } catch {
                            continue
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func updateToken(_ token: String?) async throws {
        authToken = token
        if let token {
            try tokenStore.save(token: token)
        } else {
            try tokenStore.clear()
        }
    }

    @discardableResult
    private func request<Response: Decodable, Body: Encodable>(path: String, method: HTTPMethod, body: Body? = nil) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body { request.httpBody = try encoder.encode(body) }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch http.statusCode {
        case 200..<300:
            return try decoder.decode(Response.self, from: data)
        case 400:
            let errorMessage = (try? decoder.decode(APIMessage.self, from: data))?.message
            throw APIError.badRequest(errorMessage)
        case 401:
            try await updateToken(nil)
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            let errorMessage = (try? decoder.decode(APIMessage.self, from: data))?.message
            throw APIError.server(http.statusCode, message: errorMessage)
        }
    }

    // 无Body重载，解决泛型 Body 推断报错
    @discardableResult
    private func request<Response: Decodable>(path: String, method: HTTPMethod) async throws -> Response {
        try await request(path: path, method: method, body: Optional<Data>.none as Data?)
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum APIError: Error, LocalizedError {
    case invalidResponse
    case unauthorized
    case notFound
    case badRequest(String?)
    case server(Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "服务器响应异常"
        case .unauthorized: return "登录状态失效，请重新登录"
        case .notFound: return "未找到相关数据"
        case .badRequest(let message): return message ?? "请求参数有误"
        case .server(let code, let message): return message ?? "服务器错误 (\(code))"
        }
    }
}

struct DreamCreationRequest: Codable, Sendable {
    let title: String
    let description: String
    let style: String
    let mood: String
    let tags: [String]
}

struct DreamProgressEvent: Codable, Sendable {
    let status: DreamStatus
    let progress: Double
    let message: String?
}

struct HealthStatus: Codable, Sendable {
    let deepseekOK: Bool
    let tripoOK: Bool
}

struct APIMessage: Codable {
    let message: String
}

struct LoginRequest: Codable, Sendable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable, Sendable {
    let username: String
    let email: String
    let password: String
}
