import SwiftUI

struct DreamCreationFlow: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @StateObject private var viewModel = DreamCreationViewModel()
    @State private var showResetAlert = false

    var body: some View {
        ZStack {
            Color.dreamechoBackground.ignoresSafeArea()
        NavigationStack(path: $viewModel.path) {
            stepView(for: viewModel.currentStep)
                .navigationDestination(for: DreamCreationStep.self) { step in
                    stepView(for: step)
                }
                .navigationTitle(viewModel.currentStep.navigationTitle)
                    .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbar { toolbarContent }
            }
        }
        .toast(message: $viewModel.toastMessage)
        .task { viewModel.bind(appState: appState, coordinator: coordinator) }
        .alert("清空当前创作？", isPresented: $showResetAlert) {
            Button("保留", role: .cancel) {}
            Button("清空", role: .destructive) { viewModel.reset() }
        } message: {
            Text("将清除已填写的梦境内容，但不会影响已生成结果。")
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if viewModel.currentStep == .description {
                Button {
                    showResetAlert = true
                } label: {
                    Label("清空", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.dreamechoPrimary)
                .disabled(!viewModel.canReset)
            } else {
                Button {
                    viewModel.goBack()
                } label: {
                    Label("返回", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.dreamechoPrimary)
            }
        }

        ToolbarItem(placement: .primaryAction) {
            if viewModel.currentStep == .progress, !viewModel.isSubmitting {
                Button("完成") {
                    viewModel.finish()
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.dreamechoPrimary)
            }
        }
    }

    @ViewBuilder
    private func stepView(for step: DreamCreationStep) -> some View {
        switch step {
        case .description: DreamDescriptionStep(viewModel: viewModel)
        case .review: DreamReviewStep(viewModel: viewModel)
        case .progress: DreamProgressStep(viewModel: viewModel)
        }
    }
}

enum DreamCreationStep: Int, CaseIterable, Hashable {
    case description
    case review
    case progress

    var navigationTitle: String {
        switch self {
        case .description: return "梦境工坊"
        case .review: return "确认生成"
        case .progress: return "DreamSync"
        }
    }

    var displayTitle: String {
        switch self {
        case .description: return "描述梦境"
        case .review: return "生成确认"
        case .progress: return "生成进度"
        }
    }

    var subtitle: String {
        switch self {
        case .description: return "越具体的描述，AI 越能理解你的梦境并自动提取关键词。"
        case .review: return "确认细节并提交 DreamSync 生成功能。"
        case .progress: return "DreamSync 正在生成 3D 模型，可随时返回梦境库查看。"
        }
    }
}

@MainActor
final class DreamCreationViewModel: ObservableObject {
    @Published var path: [DreamCreationStep] = []
    @Published var currentStep: DreamCreationStep = .description

    @Published var title = ""
    @Published var description = ""
    @Published var extractedTags: [String] = [] // 从后端提取的标签

    @Published var isSubmitting = false
    @Published var progress: Double = 0
    @Published var statusMessage = "准备就绪"
    @Published var toastMessage: String?

    private weak var appState: AppState?
    private weak var coordinator: NavigationCoordinator?
    private let dreamService: DreamService
    private var progressTask: Task<Void, Never>?

    init(dreamService: DreamService? = nil) {
        self.dreamService = dreamService ?? DreamService()
    }

    func bind(appState: AppState, coordinator: NavigationCoordinator) {
        self.appState = appState
        self.coordinator = coordinator
    }

    var canReset: Bool {
        !title.isEmpty || !description.isEmpty
    }

    func goToReview() {
        path = [.review]
        syncStep()
    }

    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
        syncStep()
    }

    func submit() {
        guard !title.isEmpty, !description.isEmpty, !isSubmitting else { return }
        path = [.review, .progress]
        syncStep()

        isSubmitting = true
        progress = 0
        statusMessage = "DreamSync 正在排队"
#if canImport(UIKit)
        HapticsManager.shared.impact()
#endif
        progressTask?.cancel()
        progressTask = Task {
            do {
                // 标签由后端自动提取，不需要传入
                let request = DreamCreationRequest(title: title, description: description, style: "", mood: "", tags: [])
                let dream = try await dreamService.submit(request: request)
                
                // 如果后端返回了标签，更新extractedTags
                if !dream.tags.isEmpty {
                    extractedTags = dream.tags
                }
                
                statusMessage = "模型生成中"
                await appState?.refreshDreams()
                try await listen(for: dream)
            } catch {
                await handle(error: error)
            }
        }
    }

    func finish() {
        reset()
        coordinator?.switchTo(.library)
    }

    func reset() {
        title = ""
        description = ""
        extractedTags = []
        statusMessage = "准备就绪"
        progress = 0
        isSubmitting = false
        path = []
        syncStep()
        progressTask?.cancel()
    }

    private func syncStep() {
        currentStep = path.last ?? .description
    }

    private func listen(for dream: Dream) async throws {
        do {
            for try await event in await dreamService.watchProgress(for: dream) {
                progress = event.progress
                statusMessage = event.message ?? event.status.progressMessage
            }
            let updated = try await dreamService.reloadDream(with: dream.id)
            progress = updated.status == .completed ? 1 : progress
            statusMessage = updated.status.progressMessage
            isSubmitting = false
            
            // 更新标签
            if !updated.tags.isEmpty {
                extractedTags = updated.tags
            }
            
#if canImport(UIKit)
            if updated.status == .completed {
                HapticsManager.shared.notify(.success)
            } else if updated.status == .failed {
                HapticsManager.shared.notify(.error)
            }
#endif
            await appState?.refreshDreams()
        } catch {
            try Task.checkCancellation()
            throw error
        }
    }

    private func handle(error: Error) async {
        progressTask?.cancel()
        isSubmitting = false
        statusMessage = "生成失败"
        toastMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
#if canImport(UIKit)
        HapticsManager.shared.notify(.error)
#endif
    }
}

private struct DreamDescriptionStep: View {
    @ObservedObject var viewModel: DreamCreationViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // 简化的标题区域，移除步骤指示器
                VStack(spacing: 12) {
                    Text(viewModel.currentStep.displayTitle)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Text(viewModel.currentStep.subtitle)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 8)
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("标题")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.textPrimary)
                        TextField("给梦境起个名字", text: $viewModel.title)
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("描述")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.textPrimary)
                        DreamEditor(text: $viewModel.description)
                    }
                }
                .glassCard()

                Button {
                    viewModel.goToReview()
                } label: {
                    Label("下一步", systemImage: "arrow.right")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.title.isEmpty || viewModel.description.isEmpty)
                .accessibilityLabel("继续到下一步")
                .accessibilityHint("填写标题和描述后可以继续")
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.bottom, 40)
            .frame(maxWidth: Layout.containerMaxWidth)
        }
        .background(Color.clear)
    }
}

private struct DreamReviewStep: View {
    @ObservedObject var viewModel: DreamCreationViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // 简化的标题区域
                VStack(spacing: 12) {
                    Text(viewModel.currentStep.displayTitle)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Text(viewModel.currentStep.subtitle)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 8)
                
                ReviewCard(viewModel: viewModel)
                
                Button {
                    viewModel.submit()
                } label: {
                    Label("提交 DreamSync", systemImage: "sparkles")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.isSubmitting)
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.bottom, 40)
            .frame(maxWidth: Layout.containerMaxWidth)
        }
        .background(Color.clear)
    }
}

private struct DreamProgressStep: View {
    @ObservedObject var viewModel: DreamCreationViewModel

    var body: some View {
        VStack(spacing: 28) {
            // 简化的标题区域
            VStack(spacing: 12) {
                Text(viewModel.currentStep.displayTitle)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text(viewModel.currentStep.subtitle)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 8)
            
            VStack(spacing: 24) {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(.linear)
                    .tint(.dreamechoSecondary)
                ParticleBackground()
                    .frame(height: 160)
                    .mask(RoundedRectangle(cornerRadius: 24, style: .continuous))
                Text(viewModel.statusMessage)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .glassCard()

            if !viewModel.isSubmitting {
                Button {
                    viewModel.finish()
                } label: {
                    Label("查看梦境库", systemImage: "square.grid.2x2")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.bottom, 40)
        .frame(maxWidth: Layout.containerMaxWidth)
        .background(Color.clear)
    }
}

private struct DreamEditor: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $text)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .frame(minHeight: 180)
                .background(Color.clear)
            Divider().background(Color.white.opacity(0.12))
            Text("提示：描述场景、情绪、光线、材质等细节，AI 会自动提取关键词用于建模。")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Color.textSecondary)
        }
    }
}

private struct ReviewCard: View {
    @ObservedObject var viewModel: DreamCreationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text(viewModel.description)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }
            Divider().background(.white.opacity(0.12))
            
            if !viewModel.extractedTags.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("AI提取的标签", systemImage: "tag.fill")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    FlowLayout(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.extractedTags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.dreamechoPrimary.opacity(0.15))
                                .foregroundStyle(Color.dreamechoPrimary)
                                .clipShape(Capsule())
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label("标签", systemImage: "tag")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Text("提交后AI会自动提取关键词作为标签")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .glassBorder()
    }
}

#Preview {
    DreamCreationFlow()
        .environmentObject(AppState())
        .environmentObject(NavigationCoordinator())
}
