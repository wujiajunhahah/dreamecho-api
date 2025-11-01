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
        do {
        let dream = try await apiClient.submitDream(request)
        pending.append(dream)
        return dream
        } catch {
            // 离线演示回退：本地假任务
            let dream = Dream(title: request.title, description: request.description, status: .processing, tags: request.tags)
            pending.append(dream)
            return dream
        }
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
                    // 离线演示回退：本地进度
                    for step in [0.2, 0.5, 0.8, 1.0] {
                        try? await Task.sleep(nanoseconds: 600_000_000)
                        let status: DreamStatus = step < 1.0 ? .processing : .completed
                        continuation.yield(DreamProgressEvent(status: status, progress: step, message: status.progressMessage))
                    }
                    continuation.finish()
                }
            }
        }
    }

    func reloadDream(with id: UUID) async throws -> Dream {
        do {
        let updated = try await apiClient.pollDream(id: id)
        pending.removeAll { $0.id == id }
        completed.removeAll { $0.id == id }
        if updated.status.isPending {
            pending.append(updated)
        } else {
            completed.append(updated)
        }
        return updated
        } catch {
            // 离线演示回退：本地完成
            if let existed = (pending + completed).first(where: { $0.id == id }) {
                var updated = existed
                updated.status = .completed
                pending.removeAll { $0.id == id }
                completed.removeAll { $0.id == id }
                completed.append(updated)
                return updated
            } else {
                let updated = Dream(id: id, title: "离线生成", description: "本地演示完成", status: .completed)
                completed.append(updated)
                return updated
            }
        }
    }
}
