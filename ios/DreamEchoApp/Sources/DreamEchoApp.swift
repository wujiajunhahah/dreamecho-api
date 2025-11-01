import SwiftUI
import AuthenticationServices

@main
struct DreamEchoApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var coordinator = NavigationCoordinator()

    var body: some Scene {
        WindowGroup {
            RootSwitcher()
                .environmentObject(appState)
                .environmentObject(coordinator)
                .task {
                    await appState.bootstrap()
                }
        }
    }
}

private struct RootSwitcher: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var coordinator: NavigationCoordinator

    var body: some View {
        Group {
            if appState.isAuthenticated {
                RootTabView()
            } else {
                InlineLoginView()
            }
        }
    }
}

private struct FallbackLoginScreen: View {
    @EnvironmentObject private var appState: AppState
    @State private var isLoading = false
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles").font(.system(size: 48)).foregroundStyle(LinearGradient.dreamecho)
            Button("以访客身份体验") { Task { await appState.loginAsGuest() } }
                .buttonStyle(GlassButtonStyle())
                .disabled(isLoading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dreamechoBackground.ignoresSafeArea())
    }
}

// 内联登录界面（遵循 HIG 与 SF Symbols 使用规范）
private struct InlineLoginView: View {
    @EnvironmentObject private var appState: AppState
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading = false
    @Namespace private var hero

    var body: some View {
        ZStack {
            Color.dreamechoBackground.ignoresSafeArea()
            VStack(spacing: 28) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(LinearGradient.dreamecho)
                    .matchedGeometryEffect(id: "logo", in: hero)
                    .scaleEffect(isLoading ? 1.05 : 1)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isLoading)

                Text("DreamEcho")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("登录").font(.headline).foregroundStyle(Color.textPrimary)
                        TextField("邮箱", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .accessibilityLabel("邮箱地址")
                            .accessibilityHint("输入您的邮箱地址用于登录")
                        SecureField("密码", text: $password)
                            .textContentType(.password)
                            .accessibilityLabel("密码")
                            .accessibilityHint("输入您的登录密码")

                        Button(action: { Task { await handleLogin() } }) {
                            Label("登录", systemImage: "arrow.right.circle.fill")
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(email.isEmpty || password.isEmpty || isLoading)
                        .accessibilityLabel("登录")
                        .accessibilityHint("使用邮箱和密码登录账户")

                        Button(action: { Task { await handleGuest() } }) {
                            Label("以访客身份体验", systemImage: "person.crop.circle.badge.questionmark")
                                .font(.body.weight(.semibold))
                        }
                        .buttonStyle(GlassButtonStyle())
                        .disabled(isLoading)
                        .accessibilityLabel("以访客身份体验")
                        .accessibilityHint("无需登录即可体验应用功能")

                        Button(action: startAppleSignIn) {
                            HStack {
                                Image(systemName: "apple.logo")
                                Text("使用 Apple 登录")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(GlassButtonStyle())
                        .accessibilityLabel("使用 Apple 登录")
                        .accessibilityHint("使用您的 Apple ID 快速登录")
                    }
                }
                .frame(maxWidth: 560)
                .padding(.horizontal, 20)

                if let error = appState.lastError {
                    Text(error).font(.footnote).foregroundStyle(.red)
                }
            }
        }
    }

    private func handleLogin() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        await appState.login(email: email, password: password)
    }

    private func handleGuest() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        await appState.loginAsGuest()
    }

    private func startAppleSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.performRequests()
        // 演示：直接本地完成（实际应在代理回调中处理）
        Task { await appState.authApple(id: UUID().uuidString, email: nil) }
    }
}
