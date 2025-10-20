import Foundation

@MainActor
final class DreamService: ObservableObject {
    @Published private(set) var pending: [Dream] = []
    @Published private(set) var completed: [Dream] = []
    @Published private(set) var lastError: String?

    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func refresh() async {
        do {
            let dreams = try await apiClient.fetchDreams()
            pending = dreams.filter { $0.status.isPending }
            completed = dreams.filter { !$0.status.isPending }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func submit(request: DreamCreationRequest) async throws -> Dream {
        let dream = try await apiClient.submitDream(request)
        pending.append(dream)
        return dream
    }

    nonisolated func watchProgress(for dream: Dream) -> AsyncThrowingStream<DreamProgressEvent, Error> {
        apiClient.streamEvents(for: dream.id)
    }

    func reloadDream(with id: UUID) async throws -> Dream {
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
