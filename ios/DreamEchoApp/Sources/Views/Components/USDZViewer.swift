import SwiftUI
import QuickLook

struct USDZViewer: View {
    let url: URL?
    @State private var showQuickLook = false

    var body: some View {
        ZStack {
            if let url = url {
                Button(action: { showQuickLook = true }) {
                    VStack(spacing: 16) {
                        Image(systemName: "cube.transparent")
                            .font(.system(size: 60))
                            .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        
                        Text("点击查看3D模型")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Text("支持AR预览")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .sheet(isPresented: $showQuickLook) {
                    QuickLookPreview(url: url)
                        .ignoresSafeArea()
                }
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text("正在加载模型...")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

private struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        
        init(url: URL) {
            self.url = url
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as QLPreviewItem
        }
    }
}

#Preview {
    USDZViewer(url: Bundle.main.url(forResource: "sample", withExtension: "usdz"))
        .frame(height: 300)
        .padding()
        .background(.black)
}
