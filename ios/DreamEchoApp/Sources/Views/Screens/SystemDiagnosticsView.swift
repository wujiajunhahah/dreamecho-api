import SwiftUI

struct SystemDiagnosticsView: View {
    @State private var status: HealthStatus? = nil
    @State private var isLoading = false
    private let api = APIClient()

    var body: some View {
        List {
            Section("服务状态") {
                row(label: "DeepSeek", ok: status?.deepseekOK)
                row(label: "Tripo 3D", ok: status?.tripoOK)
            }
        }
        .task { await run() }
        .navigationTitle("系统诊断")
        .toolbar { 
            ToolbarItem(placement: .primaryAction) { 
                Button("重试") { Task { await run() } }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.dreamechoPrimary)
                    .disabled(isLoading) 
            } 
        }
    }

    private func row(label: String, ok: Bool?) -> some View {
        HStack {
            Text(label)
            Spacer()
            if let ok {
                Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill").foregroundStyle(ok ? .green : .red)
            } else {
                ProgressView()
            }
        }
    }

    private func run() async {
        guard !isLoading else { return }
        isLoading = true
        status = await api.health()
        isLoading = false
    }
}



