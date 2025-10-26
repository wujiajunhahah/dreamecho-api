import SwiftUI

struct DreamCreationFlow: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @StateObject private var viewModel = DreamCreationViewModel()
    @State private var showResetAlert = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.dreamechoBackground, Color.black], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            ParticleBackground()
                .ignoresSafeArea()
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
                .disabled(!viewModel.canReset)
            } else {
                Button {
                    viewModel.goBack()
                } label: {
                    Label("返回", systemImage: "chevron.left")
                }
            }
        }

        ToolbarItem(placement: .primaryAction) {
            if viewModel.currentStep == .progress, !viewModel.isSubmitting {
                Button("完成") {
                    viewModel.finish()
                }
            }
        }
    }

    @ViewBuilder
    private func stepView(for step: DreamCreationStep) -> some View {
        switch step {
        case .description: DreamDescriptionStep(viewModel: viewModel)
        case .styling: DreamStylingStep(viewModel: viewModel)
        case .review: DreamReviewStep(viewModel: viewModel)
        case .progress: DreamProgressStep(viewModel: viewModel)
        }
    }
}

enum DreamCreationStep: Int, CaseIterable, Hashable {
    case description
    case styling
    case review
    case progress

    var navigationTitle: String {
        switch self {
        case .description: return "梦境工坊"
        case .styling: return "情绪与风格"
        case .review: return "确认生成"
        case .progress: return "DreamSync"
        }
    }

    var displayTitle: String {
        switch self {
        case .description: return "描述梦境"
        case .styling: return "设定风格"
        case .review: return "生成确认"
        case .progress: return "生成进度"
        }
    }

    var subtitle: String {
        switch self {
        case .description: return "越具体的描述，AI 越能理解你的梦境语气。"
        case .styling: return "选择梦境的情绪、艺术风格以及链上配置。"
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
    @Published var selectedMood: Mood = .serene
    @Published var selectedStyle: Style = .ethereal
    @Published var selectedBlockchain: BlockchainOption = .ethereum
    @Published var tags: [String] = []

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
        !title.isEmpty || !description.isEmpty || !tags.isEmpty || selectedMood != .serene || selectedStyle != .ethereal || selectedBlockchain != .ethereum
    }

    func goToStyling() {
        path = [.styling]
        syncStep()
    }

    func goToReview() {
        path = [.styling, .review]
        syncStep()
    }

    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
        syncStep()
    }

    func submit() {
        guard !title.isEmpty, !description.isEmpty, !isSubmitting else { return }
        path = [.styling, .review, .progress]
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
                let request = DreamCreationRequest(title: title, description: description, style: selectedStyle.rawValue, mood: selectedMood.rawValue, blockchain: selectedBlockchain, tags: tags)
                let dream = try await dreamService.submit(request: request)
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
        selectedMood = .serene
        selectedStyle = .ethereal
        selectedBlockchain = .ethereum
        tags = []
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

enum Mood: String, CaseIterable, Identifiable {
    case serene = "宁静"
    case adventurous = "冒险"
    case mysterious = "神秘"
    case vibrant = "绚烂"

    var id: String { rawValue }
}

enum Style: String, CaseIterable, Identifiable {
    case ethereal = "空灵"
    case cyberpunk = "赛博朋克"
    case biomorphic = "仿生"
    case minimal = "极简"

    var id: String { rawValue }
}

private struct DreamDescriptionStep: View {
    @ObservedObject var viewModel: DreamCreationViewModel
    @State private var tagDraft = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StepHeader(step: .description, active: viewModel.currentStep)
                VStack(spacing: 18) {
                    TextField("梦境标题", text: $viewModel.title)
                        .textFieldStyle(.roundedBorder)
                    DreamEditor(text: $viewModel.description)
                    TagInputField(tags: $viewModel.tags, draft: $tagDraft)
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .glassBorder()

                Button {
                    viewModel.goToStyling()
                } label: {
                    Label("下一步", systemImage: "arrow.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.title.isEmpty || viewModel.description.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .frame(maxWidth: 820)
        }
        .background(Color.clear)
    }
}

private struct DreamStylingStep: View {
    @ObservedObject var viewModel: DreamCreationViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StepHeader(step: .styling, active: viewModel.currentStep)
                VStack(spacing: 16) {
                    PickerSection(title: "梦境情绪") {
                        Picker("情绪", selection: $viewModel.selectedMood) {
                            ForEach(Mood.allCases) { mood in Text(mood.rawValue).tag(mood) }
                        }
                        .pickerStyle(.segmented)
                    }
                    PickerSection(title: "艺术风格") {
                        Picker("风格", selection: $viewModel.selectedStyle) {
                            ForEach(Style.allCases) { style in Text(style.rawValue).tag(style) }
                        }
                        .pickerStyle(.segmented)
                    }
                    PickerSection(title: "区块链部署") {
                        Picker("区块链", selection: $viewModel.selectedBlockchain) {
                            ForEach(BlockchainOption.allCases) { option in Text(option.displayName).tag(option) }
                        }
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .glassBorder()

                Button {
                    viewModel.goToReview()
                } label: {
                    Label("确认设定", systemImage: "checkmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .frame(maxWidth: 820)
        }
        .background(Color.clear)
    }
}

private struct DreamReviewStep: View {
    @ObservedObject var viewModel: DreamCreationViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StepHeader(step: .review, active: viewModel.currentStep)
                ReviewCard(viewModel: viewModel)
                Button {
                    viewModel.submit()
                } label: {
                    Label("提交 DreamSync", systemImage: "sparkles")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.isSubmitting)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .frame(maxWidth: 820)
        }
        .background(Color.clear)
    }
}

private struct DreamProgressStep: View {
    @ObservedObject var viewModel: DreamCreationViewModel

    var body: some View {
        VStack(spacing: 28) {
            StepHeader(step: .progress, active: viewModel.currentStep)
            VStack(spacing: 24) {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(.linear)
                    .tint(.dreamechoSecondary)
                ParticleBackground()
                    .frame(height: 160)
                    .mask(RoundedRectangle(cornerRadius: 24, style: .continuous))
                Text(viewModel.statusMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .glassBorder()

            if !viewModel.isSubmitting {
                Button {
                    viewModel.finish()
                } label: {
                    Label("查看梦境库", systemImage: "square.grid.2x2")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .frame(maxWidth: 820)
        .background(Color.clear)
    }
}

private struct StepHeader: View {
    let step: DreamCreationStep
    let active: DreamCreationStep

    var body: some View {
        VStack(spacing: 18) {
            DreamStepIndicator(activeStep: active)
            VStack(spacing: 6) {
                Text(step.displayTitle).font(AppFont.heading(26))
                Text(step.subtitle).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct DreamEditor: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $text)
                .frame(minHeight: 180)
                .background(Color.clear)
            Divider().background(Color.white.opacity(0.12))
            Text("提示：描述场景、情绪、光线、材质等细节，AI 会提取关键词用于建模。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct TagInputField: View {
    @Binding var tags: [String]
    @Binding var draft: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("添加标签（例如 星尘 / 森林 / AR）", text: $draft, onCommit: addTag)
                    .textFieldStyle(.roundedBorder)
                if !draft.isEmpty {
                    Button("添加") { addTag() }
                        .buttonStyle(.borderedProminent)
                }
            }
            if !tags.isEmpty {
                FlowLayout(alignment: .leading, spacing: 8, minWidth: 80) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 6) {
                            Text(tag).font(.caption)
                            Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                        .onTapGesture { remove(tag) }
                    }
                }
            }
        }
    }

    private func addTag() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        draft = ""
    }

    private func remove(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

private struct PickerSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.callout.weight(.medium))
            content
        }
    }
}

private struct ReviewCard: View {
    @ObservedObject var viewModel: DreamCreationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.title).font(AppFont.heading(24))
                Text(viewModel.description).font(.callout).foregroundStyle(.secondary)
            }
            Divider().background(.white.opacity(0.12))
            Grid(horizontalSpacing: 18, verticalSpacing: 12) {
                GridRow { Label("情绪", systemImage: "face.smiling") ; Text(viewModel.selectedMood.rawValue) }
                GridRow { Label("风格", systemImage: "paintbrush") ; Text(viewModel.selectedStyle.rawValue) }
                GridRow { Label("区块链", systemImage: "link") ; Text(viewModel.selectedBlockchain.displayName) }
                if !viewModel.tags.isEmpty {
                    GridRow { Label("标签", systemImage: "tag") ; Text(viewModel.tags.joined(separator: "、")) }
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
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
