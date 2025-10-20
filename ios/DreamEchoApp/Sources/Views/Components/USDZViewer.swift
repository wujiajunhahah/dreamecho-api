import SwiftUI
import QuickLook
import ARKit
import RealityKit

struct USDZViewer: View {
    let url: URL?
    @State private var showQuickLook = false

    var body: some View {
        ZStack {
            if let url {
                RealityPreview(url: url)
                    .onTapGesture { showQuickLook = true }
                    .sheet(isPresented: $showQuickLook) {
                        QuickLookPreview(url: url)
                    }
            } else {
                Placeholder()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .glassBorder()
    }
}

private struct Placeholder: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("正在加载 USDZ")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

private struct RealityPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        view.environment.background = .color(.black)
        Task { await loadModel(into: view) }
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    private func loadModel(into view: ARView) async {
        do {
            let entity = try await ModelEntity.loadAsync(contentsOf: url)
            let anchor = AnchorEntity(world: .zero)
            entity.scale = SIMD3<Float>(repeating: 0.6)
            anchor.addChild(entity)
            view.scene.anchors.removeAll()
            view.scene.addAnchor(anchor)
        } catch {
            print("USDZ load error: \(error)")
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

    func updateUIViewController(_ controller: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(url: url) }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        private let item: QLPreviewItemWrapper

        init(url: URL) {
            item = QLPreviewItemWrapper(url: url)
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem { item }

        private final class QLPreviewItemWrapper: NSObject, QLPreviewItem {
            let previewItemURL: URL?
            init(url: URL) { previewItemURL = url }
        }
    }
}
