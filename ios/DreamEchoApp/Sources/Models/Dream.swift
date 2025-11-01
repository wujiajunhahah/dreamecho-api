import Foundation

struct Dream: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var title: String
    var description: String
    var status: DreamStatus
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var previewImageURL: URL?
    var modelURL: URL?
    // 移除虚拟货币相关字段，保持纯生成/浏览流程

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        status: DreamStatus,
        tags: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now,
        previewImageURL: URL? = nil,
        modelURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.previewImageURL = previewImageURL
        self.modelURL = modelURL
    }
    
    // 自定义解码器，支持后端返回的字符串ID
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case status
        case tags
        case createdAt
        case updatedAt
        case previewImageURL
        case modelURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 处理ID：可能是UUID字符串或数字字符串
        let idString = try container.decode(String.self, forKey: .id)
        if let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            // 如果不是UUID格式，基于字符串生成确定性UUID
            let hash = idString.hashValue
            let uuidString = String(format: "00000000-0000-0000-0000-%012x", abs(hash) % 0xFFFFFFFFFFFF)
            self.id = UUID(uuidString: uuidString) ?? UUID()
        }
        
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        
        // 处理status：可能是字符串或枚举
        let statusString = try container.decode(String.self, forKey: .status)
        status = DreamStatus(rawValue: statusString) ?? .pending
        
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        
        // 处理日期
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        createdAt = formatter.date(from: createdAtString) ?? ISO8601DateFormatter().date(from: createdAtString) ?? Date()
        
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        updatedAt = formatter.date(from: updatedAtString) ?? ISO8601DateFormatter().date(from: updatedAtString) ?? Date()
        
        // 处理可选的URL
        if let previewURLString = try? container.decodeIfPresent(String.self, forKey: .previewImageURL), !previewURLString.isEmpty {
            previewImageURL = URL(string: previewURLString)
        } else {
            previewImageURL = nil
        }
        
        if let modelURLString = try? container.decodeIfPresent(String.self, forKey: .modelURL), !modelURLString.isEmpty {
            modelURL = URL(string: modelURLString)
        } else {
            modelURL = nil
        }
    }
}

enum DreamStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed

    var isPending: Bool { self == .pending || self == .processing }

    var localizedDescription: String {
        switch self {
        case .pending: return "待处理"
        case .processing: return "生成中"
        case .completed: return "已完成"
        case .failed: return "失败"
        }
    }

    var iconName: String {
        switch self {
        case .pending: return "clock"
        case .processing: return "hourglass"
        case .completed: return "checkmark.seal"
        case .failed: return "exclamationmark.triangle"
        }
    }

    var progressMessage: String {
        switch self {
        case .pending, .processing: return "DreamSync 正在生成"
        case .completed: return "模型生成完成"
        case .failed: return "生成失败，请重试"
        }
    }
}

// 已移除 BlockchainOption

struct User: Codable, Sendable {
    let id: UUID
    let username: String
    let email: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 处理ID：可能是UUID字符串或数字字符串
        let idString = try container.decode(String.self, forKey: .id)
        if let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            // 如果不是UUID格式，基于字符串生成确定性UUID
            let hash = idString.hashValue
            let uuidString = String(format: "00000000-0000-0000-0000-%012x", abs(hash) % 0xFFFFFFFFFFFF)
            self.id = UUID(uuidString: uuidString) ?? UUID()
        }
        
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
    }
    
    init(id: UUID, username: String, email: String) {
        self.id = id
        self.username = username
        self.email = email
    }
}

extension Dream {
    static let showcase: [Dream] = [
        Dream(title: "云海玻璃花园", description: "漂浮在云端的液态玻璃温室，星光植物随呼吸闪烁。", status: .completed, tags: ["梦境", "自然"]),
        Dream(title: "霓虹流星骑士", description: "穿梭霓虹迷宫的蒸汽朋克骑士，披风由流星光编织而成。", status: .completed, tags: ["角色", "赛博朋克"]),
        Dream(title: "水墨龙魂", description: "从东方墨色中觉醒的龙魂，萦绕着古老的钟声。", status: .completed, tags: ["东方", "神话"])
    ]

    static let pendingSamples: [Dream] = [
        Dream(title: "星际列车", description: "携带记忆碎片的透明列车穿过银河。", status: .processing, tags: ["旅行", "科幻"]),
        Dream(title: "林间光影", description: "晨雾森林里鹿角与萤火交织。", status: .pending, tags: ["自然", "治愈"])
    ]
}
