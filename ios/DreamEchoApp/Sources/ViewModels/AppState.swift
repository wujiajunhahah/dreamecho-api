import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var session: UserSession?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var pendingDreams: [Dream] = []
    @Published private(set) var completedDreams: [Dream] = []
    @Published var selectedDream: Dream?
    @Published var showARViewer = false
    @Published var lastError: String?

    private let authService: AuthService
    private let dreamService: DreamService

    nonisolated init(authService: AuthService = AuthService(), dreamService: DreamService = DreamService()) {
        self.authService = authService
        self.dreamService = dreamService
    }

    func bootstrap() async {
        await authService.bootstrap()
        session = authService.session
        isAuthenticated = session != nil
        await refreshDreams()
    }

    func login(email: String, password: String) async {
        do {
            try await authService.login(email: email, password: password)
            session = authService.session
            isAuthenticated = true
            await refreshDreams()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func register(username: String, email: String, password: String) async {
        do {
            try await authService.register(username: username, email: email, password: password)
            session = authService.session
            isAuthenticated = true
            await refreshDreams()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func logout() async {
        await authService.logout()
        session = nil
        isAuthenticated = false
        pendingDreams = []
        completedDreams = []
    }

    func refreshDreams() async {
        await dreamService.refresh()
        pendingDreams = dreamService.pending.isEmpty ? Dream.pendingSamples : dreamService.pending
        completedDreams = dreamService.completed.isEmpty ? Dream.showcase : dreamService.completed
        lastError = dreamService.lastError
    }
}
