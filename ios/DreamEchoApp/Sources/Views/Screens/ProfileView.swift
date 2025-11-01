import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var enableNotifications = true
    @State private var enableHaptics = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Layout.verticalSectionSpacing) {
                if let user = appState.session?.user {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("账户").font(.headline).foregroundStyle(Color.textPrimary)
                        LabeledContent("用户名", value: user.username)
                        LabeledContent("邮箱", value: user.email)
                            }
                    }
                }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("体验设置").font(.headline).foregroundStyle(Color.textPrimary)
                    Toggle("启用通知", isOn: $enableNotifications)
                    Toggle("启用触感反馈", isOn: $enableHaptics)
                        }
                }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("系统").font(.headline).foregroundStyle(Color.textPrimary)
                    Button("同步梦境") {
                        Task { await appState.refreshDreams() }
                    }
                    .buttonStyle(GlassButtonStyle())
                        NavigationLink("系统诊断") { InlineSystemDiagnosticsView() }
                    Button("退出登录", role: .destructive) {
                        Task { await appState.logout() }
                    }
                    .buttonStyle(GlassButtonStyle())
                }
            }
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.vertical, 24)
                .frame(maxWidth: Layout.containerMaxWidth)
            }
            .background(Color.dreamechoBackground.ignoresSafeArea())
            .navigationTitle("个人中心")
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}

// 内联系统诊断，避免新文件未纳入工程导致编译失败
private struct InlineSystemDiagnosticsView: View {
    @State private var deepseekOK: Bool? = nil
    @State private var tripoOK: Bool? = nil
    private let api = APIClient()
    var body: some View {
        List {
            Section("服务状态") {
                row("DeepSeek", deepseekOK)
                row("Tripo 3D", tripoOK)
            }
        }
        .task { await run() }
        .navigationTitle("系统诊断")
    }
    private func row(_ label: String, _ ok: Bool?) -> some View {
        HStack { Text(label); Spacer(); indicator(ok) }
    }
    private func indicator(_ ok: Bool?) -> some View {
        Group {
            if let ok { Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill").foregroundStyle(ok ? .green : .red) }
            else { ProgressView() }
        }
    }
    private func run() async {
        let status = await api.health()
        deepseekOK = status.deepseekOK
        tripoOK = status.tripoOK
    }
}
