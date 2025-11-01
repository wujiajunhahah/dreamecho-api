import Foundation

@MainActor
final class DreamService: ObservableObject {
    @Published private(set) var pending: [Dream] = []
    @Published private(set) var completed: [Dream] = []
    @Published private(set) var lastError: String?

    private let apiClient: APIClient

    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? APIClient()
    }

    func refresh() async {
        do {
            let dreams = try await apiClient.fetchDreams()
            pending = dreams.filter { $0.status.isPending }
            completed = dreams.filter { !$0.status.isPending }
            lastError = nil
        } catch {
            // 移除假数据回退，只记录错误
            lastError = error.localizedDescription
            print("❌ 获取梦境列表失败: \(error.localizedDescription)")
        }
    }

    func submit(request: DreamCreationRequest) async throws -> Dream {
        // 只调用真实API，失败时抛出错误
        let dream = try await apiClient.submitDream(request)
        pending.append(dream)
        return dream
    }

    func watchProgress(for dream: Dream) async -> AsyncThrowingStream<DreamProgressEvent, Error> {
        let remote = await apiClient.streamEvents(for: dream.id)
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await event in remote {
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch {
                    // API失败时直接结束流，不显示假进度
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func reloadDream(with id: UUID) async throws -> Dream {
        // 只调用真实API，失败时抛出错误
        let updated = try await apiClient.pollDream(id: id)
        pending.removeAll { $0.id == id }
        completed.removeAll { $0.id == id }
        if updated.status.isPending {
            pending.append(updated)
        } else {
            completed.append(updated)
        }
        return updated
    }
}
