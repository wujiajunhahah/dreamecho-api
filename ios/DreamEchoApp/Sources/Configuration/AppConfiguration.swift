import Foundation

struct AppConfiguration {
    static let shared = AppConfiguration()

    let baseURL: URL
    let eventsURL: URL
    let enableHaptics: Bool

    private init(bundle: Bundle = .main, environment: [String: String] = ProcessInfo.processInfo.environment) {
        let info = bundle.infoDictionary ?? [:]
        // 优先使用环境变量，然后是 Info.plist，最后是默认值
        // 生产环境使用 Info.plist 中的 https://api.dreamecho.ai
        // 开发环境可以使用 localhost:5001
        let base = environment["API_BASE_URL"] ?? info["API_BASE_URL"] as? String ?? "https://api.dreamecho.ai"
        let events = environment["API_EVENTS_URL"] ?? info["API_EVENTS_URL"] as? String ?? base
        enableHaptics = (environment["ENABLE_HAPTICS"] ?? info["ENABLE_HAPTICS"] as? String ?? "true").lowercased() != "false"

        guard let baseURL = URL(string: base), let eventsURL = URL(string: events) else {
            fatalError("Invalid API_BASE_URL or API_EVENTS_URL configuration")
        }
        self.baseURL = baseURL
        self.eventsURL = eventsURL
        
        // 调试输出
        #if DEBUG
        print("🌐 API配置:")
        print("   Base URL: \(baseURL)")
        print("   Events URL: \(eventsURL)")
        print("   触感反馈: \(enableHaptics)")
        #endif
    }
}
