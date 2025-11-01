import SwiftUI

struct DreamAnalysisView: View {
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



