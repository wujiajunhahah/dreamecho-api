import SwiftUI

struct DreamLibraryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var searchText = ""
    @State private var segment: LibrarySegment = .mine
    @State private var toastMessage: String?
    @State private var isRefreshing = false

    private var source: [Dream] {
        switch segment {
        case .mine: 
            // 只显示用户自己的真实梦境
            return appState.completedDreams
        case .inspiration:
            // 可以从后端获取公开的精选梦境
            return appState.completedDreams.filter { $0.status == .completed }
        }
    }

    private var filteredDreams: [Dream] {
        guard !searchText.isEmpty else { return source }
        return source.filter { dream in
            dream.title.localizedCaseInsensitiveContains(searchText) ||
            dream.description.localizedCaseInsensitiveContains(searchText) ||
            dream.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        LibraryHeader(completed: appState.completedDreams.count, pending: appState.pendingDreams.count, showcase: Dream.showcase.count)
                        
                        Picker("梦境视图", selection: $segment) {
                            ForEach(LibrarySegment.allCases, id: \.self) { segment in
                                Text(segment.title).tag(segment)
                            }
                        }
                        .pickerStyle(.segmented)
                        .glassBorder()
                        
                        if filteredDreams.isEmpty {
                            EmptyState(segment: segment)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 48)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 24)], spacing: 24) {
                                ForEach(filteredDreams) { dream in
                                    DreamCard(dream: dream)
                                        .onTapGesture {
                                            appState.selectedDream = dream
                                            appState.showARViewer = true
                                        }
                                }
                            }
                            .animation(.spring(response: 0.45, dampingFraction: 0.78), value: filteredDreams)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 60)
                    .padding(.top, 16)
                }
                .background(
                    ZStack {
                        Color.dreamechoBackground.ignoresSafeArea()
                        // 添加渐变背景而不是黑色
                        LinearGradient(
                            colors: [
                                Color.dreamechoBackground.opacity(0.8),
                                Color.dreamechoPrimary.opacity(0.05),
                                Color.dreamechoBackground
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                    }
                )
                .navigationTitle("梦境档案")
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索标题或标签")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task { await refresh() }
                        } label: {
                            if isRefreshing {
                                ProgressView()
                            } else {
                                Label("刷新", systemImage: "arrow.clockwise")
                            }
                        }
                        .disabled(isRefreshing)
                    }
                }
                .sheet(isPresented: $appState.showARViewer) {
                    if let dream = appState.selectedDream {
                        DreamDetailView(dream: dream, isPresented: $appState.showARViewer)
                            .presentationDetents([.large])
                    }
                }
            }
            .toast(message: $toastMessage)
            .task { await refresh() }
            .onChange(of: appState.lastError) { oldValue, newValue in
                toastMessage = newValue
            }
        } else {
            // Fallback on earlier versions
        }
    }

    private func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        await appState.refreshDreams()
        isRefreshing = false
    }
}

enum LibrarySegment: Int, CaseIterable {
    case mine
    case inspiration

    var title: String {
        switch self {
        case .mine: return "我的梦境"
        case .inspiration: return "灵感探索"
        }
    }
}

private struct LibraryHeader: View {
    let completed: Int
    let pending: Int
    let showcase: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("梦境旅程总览").font(AppFont.heading(32)).foregroundStyle(LinearGradient.dreamecho)
            HStack(spacing: 16) {
                StatTile(title: "已完成", value: completed, caption: "可下载 / USDZ 预览")
                StatTile(title: "生成中", value: pending, caption: "DreamSync 队列")
                StatTile(title: "精选库", value: showcase, caption: "灵感案例")
            }
        }
    }
}

private struct StatTile: View {
    let title: String
    let value: Int
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text("\(value)").font(AppFont.heading(30))
            Text(caption).font(.caption).foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .glassBorder()
    }
}

private struct EmptyState: View {
    let segment: LibrarySegment

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles.rectangle.stack").font(.system(size: 44)).foregroundStyle(LinearGradient.dreamecho)
            Text(segment == .mine ? "还没有生成梦境" : "灵感正在上传")
                .font(.title3.weight(.semibold))
            Text(segment == .mine ? "在梦境工坊描述你的第一个梦境，完成后将同步到这里。" : "团队正在准备更多精选作品，稍后回来查看更多灵感。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .glassBorder()
    }
}

private struct DreamCard: View {
    let dream: Dream

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AsyncImage(url: dream.previewImageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Color.black.opacity(0.2)
                        .overlay(Image(systemName: "photo").font(.system(size: 32)).foregroundStyle(.secondary))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Text(dream.title).font(.headline)
                Text(dream.description).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
                if !dream.tags.isEmpty {
                    FlowLayout(alignment: .leading, spacing: 8) {
                        ForEach(dream.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            HStack {
                Label(dream.status.localizedDescription, systemImage: dream.status.iconName)
                Spacer()
                Label("查看", systemImage: "eye")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .glassBorder()
    }
}

private struct DreamDetailView: View {
    let dream: Dream
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    USDZViewer(url: dream.modelURL)
                        .frame(height: 320)
                    DetailCard(dream: dream)
                }
                .padding()
            }
            .background(
                ZStack {
                    Color.dreamechoBackground.ignoresSafeArea()
                    LinearGradient(
                        colors: [
                            Color.dreamechoBackground.opacity(0.8),
                            Color.dreamechoPrimary.opacity(0.05),
                            Color.dreamechoBackground
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
            )
            .navigationTitle("梦境详情")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { isPresented = false }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.dreamechoPrimary)
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: dream.modelURL ?? URL(string: "https://dreamecho.ai")!) {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

private struct DetailCard: View {
    let dream: Dream

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(dream.title).font(AppFont.heading(28))
            Text(dream.description).font(.body).foregroundStyle(.secondary)
            Divider().background(.white.opacity(0.2))
            if !dream.tags.isEmpty { InfoRow(label: "标签", value: dream.tags.joined(separator: "、"), icon: "tag") }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .glassBorder()
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(LinearGradient.dreamecho).frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.body)
            }
        }
    }
}

#Preview {
    DreamLibraryView()
        .environmentObject(AppState())
}
