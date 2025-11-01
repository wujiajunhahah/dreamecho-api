import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var coordinator: NavigationCoordinator

    private var hasCompletedDreams: Bool { !appState.completedDreams.isEmpty }
    private var hasPendingDreams: Bool { !appState.pendingDreams.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.verticalSectionSpacing) {
                PillHeader(onCreate: { coordinator.switchTo(.creation) })
                HomeList()
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, Layout.verticalSectionSpacing)
            .frame(maxWidth: 560)
        }
        .background(Color.dreamechoBackground.ignoresSafeArea())
    }
}

private enum HomeSegment: Int, CaseIterable, Identifiable, CustomStringConvertible {
    case overview, create, explore
    var id: Int { rawValue }
    var description: String {
        switch self { case .overview: return "概览"; case .create: return "创作"; case .explore: return "探索" }
    }
}

private struct PillHeader: View {
    @State private var segment: HomeSegment = .overview
    let onCreate: () -> Void
    var body: some View {
        HStack {
            HomePills(selection: $segment)
            Spacer()
                Button(action: onCreate) { 
                    Label("新建梦境", systemImage: "plus") 
                        .accessibilityLabel("创建新梦境")
                        .accessibilityHint("打开梦境创作工坊")
                }
                .buttonStyle(GlassButtonStyle())
            }
    }
}

private struct HomeList: View {
    @EnvironmentObject private var appState: AppState
    @State private var segment: HomeSegment = .overview
    var body: some View {
        VStack(spacing: Layout.verticalSectionSpacing) {
            switch segment {
            case .overview:
                Group {
                    ListRow(icon: "sparkles", title: "新建梦境", subtitle: "从文本生成 3D 场景", trailing: "开始")
                    NavigationLink {
                        if let first = appState.pendingDreams.first ?? appState.completedDreams.first {
                            DreamAnalysisView(dream: first)
                        } else {
                            GlassPlaceholder(icon: "hourglass", title: "暂无任务", message: "生成后可查看解析与模型。")
                        }
                    } label: {
                        ListRow(icon: "doc.text.magnifyingglass", title: "解析查看", subtitle: "最近一次任务详情", trailing: "进入")
                    }
                    ListRow(icon: "checkmark.seal", title: "最近完成", subtitle: "USDZ 预览与分享", trailing: "打开")
                }
            case .create:
                Group {
                    ListRow(icon: "wand.and.stars", title: "梦境工坊", subtitle: "描述、情绪、风格与标签", trailing: "进入")
                    ListRow(icon: "paintpalette", title: "风格与情绪", subtitle: "设置视觉基调与氛围", trailing: "设置")
                    ListRow(icon: "tag", title: "标签管理", subtitle: "组织主题与检索", trailing: "管理")
                }
            case .explore:
                Group {
                    ListRow(icon: "square.grid.2x2", title: "灵感探索", subtitle: "社区精选案例与素材", trailing: "浏览")
                    ListRow(icon: "book", title: "教程与指南", subtitle: "快速掌握创作流程", trailing: "阅读")
                    ListRow(icon: "gearshape", title: "偏好与设置", subtitle: "通知、触感、登录", trailing: "打开")
                }
            }
        }
        .glassCard(cornerRadius: 20, contentPadding: 16)
    }
}

// 本地内联分段控件，避免工程文件未包含导致的编译问题
private struct HomePills: View {
    @Binding var selection: HomeSegment
    var body: some View {
        HStack(spacing: 12) {
            pill(.overview)
            pill(.create)
            pill(.explore)
        }
    }
    private func pill(_ seg: HomeSegment) -> some View {
        Button(action: { selection = seg }) {
            Text(seg.description)
                .font(.body.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selection == seg ? Color.dreamechoSecondary.opacity(0.2) : Color.black.opacity(0.06))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ListRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let trailing: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 22)).frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.body.weight(.semibold)).foregroundStyle(Color.textPrimary)
                Text(subtitle).font(.footnote).foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Text(trailing).font(.footnote).foregroundStyle(.secondary)
            Image(systemName: "chevron.right").font(.footnote).foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
    }
}

// Inline 解析页，避免工程未纳入新文件导致的找不到符号
private struct DreamAnalysisView: View {
    let dream: Dream
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.verticalSectionSpacing) {
                ListRow(icon: "text.magnifyingglass", title: "解析结果", subtitle: "关键词、情绪、风格与标签", trailing: "查看")
                ListRow(icon: "square.and.arrow.down", title: "模型文件", subtitle: "USDZ/GLB 预览与分享", trailing: "打开")
                ListRow(icon: "wand.and.stars", title: "再次生成", subtitle: "基于当前描述快速重试", trailing: "开始")
            }
            .glassCard(cornerRadius: 20, contentPadding: 16)
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, Layout.verticalSectionSpacing)
            .frame(maxWidth: 560)
        }
        .background(Color.dreamechoBackground.ignoresSafeArea())
        .navigationTitle("解析 · \(dream.title)")
    }
}

private struct PendingCarousel: View {
    let dreams: [Dream]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(title: "DreamSync 进度", subtitle: "实时追踪生成状态")
            if dreams.isEmpty {
                GlassPlaceholder(icon: "hourglass", title: "暂无任务", message: "在梦境工坊提交描述后将自动显示进度。")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(dreams) { dream in
                            PendingCard(dream: dream)
                        }
                    }
                    .padding(.trailing, Layout.horizontalPadding)
                }
            }
        }
        .glassCard()
    }
}

private struct PendingCard: View {
    let dream: Dream

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(dream.title).font(.headline)
            Text(dream.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Label(dream.status.progressMessage, systemImage: dream.status.iconName)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 240, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .glassBorder()
    }
}

private struct ToolingGrid: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(title: "创意工具箱", subtitle: "关键系统概览")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: Layout.gridSpacing)], spacing: Layout.gridSpacing) {
                ToolCard(icon: "cpu", title: "DeepSeek AI", description: "解析梦境语义，输出 DreamScript 与情绪标签。")
                ToolCard(icon: "cube.transparent", title: "Tripo 3D", description: "驱动 USDZ/GLB 生成功能，支持 AR 预览。")
                ToolCard(icon: "paintpalette", title: "Liquid Glass UI", description: "渐层玻璃界面与粒子背景保持沉浸体验。")
                ToolCard(icon: "cloud", title: "Xcode Cloud", description: "集成 CI/CD 与 TestFlight，保障 WWDC 演示稳定。")
            }
        }
        .glassCard()
    }
}

private struct ToolCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(LinearGradient.dreamecho)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            Text(title).font(.title3.weight(.semibold))
            Text(description).font(.callout).foregroundStyle(.secondary)
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .glassBorder()
    }
}

private struct ExplorePreview: View {
    let dreams: [Dream]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(title: "灵感探索", subtitle: "来自创作者的精选梦境")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: Layout.minCardWidthRegular), spacing: Layout.gridSpacing)], spacing: Layout.gridSpacing) {
                ForEach(dreams.prefix(3)) { dream in
                    ExploreCard(dream: dream)
                }
            }
        }
        .glassCard()
    }
}

private struct ExploreCard: View {
    let dream: Dream

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .frame(height: 140)
                .overlay(
                    VStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 34))
                            .foregroundStyle(LinearGradient.dreamecho)
                        Text("USDZ 预览")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                )
            VStack(alignment: .leading, spacing: 8) {
                Text(dream.title).font(.headline)
                Text(dream.description).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
            }
            HStack {
                Label(dream.status.localizedDescription, systemImage: dream.status.iconName)
                Spacer()
                Image(systemName: "eye")
                Text("查看")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .glassBorder()
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.title3.weight(.semibold)).foregroundStyle(Color.textPrimary)
            Text(subtitle).font(.callout).foregroundStyle(Color.textSecondary)
        }
    }
}

private struct GlassPlaceholder: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 34)).foregroundStyle(LinearGradient.dreamecho)
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .glassBorder()
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
        .environmentObject(NavigationCoordinator())
}
