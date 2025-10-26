import Foundation
#if canImport(UIKit)
import UIKit

@MainActor
final class HapticsManager {
    static let shared = HapticsManager(configuration: .shared)

    private let configuration: AppConfiguration
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)

    init(configuration: AppConfiguration) {
        self.configuration = configuration
    }

    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard configuration.enableHaptics else { return }
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(type)
    }

    func impact() {
        guard configuration.enableHaptics else { return }
        impactGenerator.prepare()
        impactGenerator.impactOccurred()
    }
}
#endif
