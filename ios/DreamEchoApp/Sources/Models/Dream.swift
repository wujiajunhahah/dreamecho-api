import Foundation

struct Dream: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var status: DreamStatus
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var previewImageURL: URL?
    var modelURL: URL?
    var blockchain: BlockchainOption
    var price: Decimal?
    var royalty: Decimal?

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        status: DreamStatus,
        tags: [String] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now,
        previewImageURL: URL? = nil,
        modelURL: URL? = nil,
        blockchain: BlockchainOption = .ethereum,
        price: Decimal? = nil,
        royalty: Decimal? = nil
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
        self.blockchain = blockchain
        self.price = price
        self.royalty = royalty
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

enum BlockchainOption: String, Codable, CaseIterable, Identifiable {
    case ethereum
    case polygon
    case bsc
    case avalanche

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ethereum: return "Ethereum"
        case .polygon: return "Polygon"
        case .bsc: return "BNB Chain"
        case .avalanche: return "Avalanche"
        }
    }
}

struct User: Codable {
    let id: UUID
    let username: String
    let email: String
}

extension Dream {
    static let showcase: [Dream] = [
        Dream(title: "云海玻璃花园", description: "漂浮在云端的液态玻璃温室，星光植物随呼吸闪烁。", status: .completed, tags: ["梦境", "自然"], blockchain: .ethereum, price: 0.24, royalty: 5),
        Dream(title: "霓虹流星骑士", description: "穿梭霓虹迷宫的蒸汽朋克骑士，披风由流星光编织而成。", status: .completed, tags: ["角色", "赛博朋克"], blockchain: .polygon, price: 0.18, royalty: 4),
        Dream(title: "水墨龙魂", description: "从东方墨色中觉醒的龙魂，萦绕着古老的钟声。", status: .completed, tags: ["东方", "神话"], blockchain: .bsc, price: 0.32, royalty: 6)
    ]

    static let pendingSamples: [Dream] = [
        Dream(title: "星际列车", description: "携带记忆碎片的透明列车穿过银河。", status: .processing, tags: ["旅行", "科幻"]),
        Dream(title: "林间光影", description: "晨雾森林里鹿角与萤火交织。", status: .pending, tags: ["自然", "治愈"])
    ]
}
