import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading = false
    @Namespace private var hero

    var body: some View {
        ZStack {
            Color.dreamechoBackground.ignoresSafeArea()

            VStack(spacing: 28) {
                // 简洁启动动画徽标（SF Symbols）
                Image(systemName: "sparkles")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(LinearGradient.dreamecho)
                    .matchedGeometryEffect(id: "logo", in: hero)
                    .scaleEffect(isLoading ? 1.05 : 1)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isLoading)

                Text("DreamEcho")
                    .font(AppFont.heading(34))
                    .foregroundStyle(Color.textPrimary)

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("登录").font(.headline).foregroundStyle(Color.textPrimary)
                        TextField("邮箱", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                        SecureField("密码", text: $password)
                            .textContentType(.password)

                        Button(action: { Task { await handleLogin() } }) {
                            Label("登录", systemImage: "arrow.right.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(email.isEmpty || password.isEmpty || isLoading)

                        Button(action: { Task { await handleGuest() } }) {
                            Label("以访客身份体验", systemImage: "person.crop.circle.badge.questionmark")
                                .font(.headline)
                        }
                        .buttonStyle(GlassButtonStyle())
                        .disabled(isLoading)
                    }
                }
                .frame(maxWidth: Layout.containerMaxWidth)
                .padding(.horizontal, Layout.horizontalPadding)

                if let error = appState.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
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
}

#Preview {
    LoginView().environmentObject(AppState())
}

