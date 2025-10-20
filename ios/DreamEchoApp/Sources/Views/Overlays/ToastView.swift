import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.footnote.weight(.medium))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.75))
            .clipShape(Capsule())
            .shadow(radius: 8)
    }
}

extension View {
    func toast(message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var message: String?
    @State private var isPresented = false

    func body(content: Content) -> some View {
        ZStack {
            content
            if let message, isPresented {
                VStack {
                    Spacer()
                    ToastView(message: message)
                        .padding(.bottom, 48)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onChange(of: message) { newValue in
            guard newValue != nil else { return }
            withAnimation(.spring()) { isPresented = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.spring()) { isPresented = false }
                self.message = nil
            }
        }
    }
}
