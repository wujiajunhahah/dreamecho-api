import SwiftUI

struct DreamStepIndicator: View {
    let activeStep: DreamCreationStep

    var body: some View {
        HStack(spacing: 16) {
            ForEach(DreamCreationStep.allCases, id: \.self) { step in
                StepItem(step: step, isActive: step == activeStep, isCompleted: step.rawValue < activeStep.rawValue)
                if step != DreamCreationStep.allCases.last {
                    Rectangle()
                        .fill(.white.opacity(0.18))
                        .frame(height: 1)
                        .overlay(LinearGradient.dreamecho.opacity(step.rawValue < activeStep.rawValue ? 0.9 : 0.3))
                }
            }
        }
        .padding(.horizontal, 12)
    }
}

private struct StepItem: View {
    let step: DreamCreationStep
    let isActive: Bool
    let isCompleted: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isActive ? AnyShapeStyle(LinearGradient.dreamecho) : AnyShapeStyle(Color.white.opacity(0.06)))
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(isCompleted ? AnyShapeStyle(LinearGradient.dreamecho) : AnyShapeStyle(Color.white.opacity(0.2)), lineWidth: 1.5))
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                        .font(.system(size: 14, weight: .bold))
                } else {
                    Text("\(step.rawValue + 1)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isActive ? .white : .white.opacity(0.6))
                }
            }
            Text(step.displayTitle)
                .font(.caption2)
                .foregroundStyle(isActive ? LinearGradient.dreamecho : .secondary)
        }
    }
}
