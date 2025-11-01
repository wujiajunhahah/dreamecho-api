import SwiftUI

struct PillSegmented<T: Hashable & CaseIterable & Identifiable & CustomStringConvertible>: View {
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(T.allCases)) { item in
                Button(action: { selection = item }) {
                    Text(item.description)
                        .font(.body.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selection == item ? Color.dreamechoSecondary.opacity(0.2) : Color.black.opacity(0.06))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}



