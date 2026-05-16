import Foundation

@Observable
@MainActor
final class TipService {

    // MARK: - State

    private(set) var recentEntries: [TipEntry] = []
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Fetch recent (last 7 by date)

    func fetchRecent() async {
        isLoading = true
        errorMessage = nil
        do {
            // Server returns the 7 most recent entries ordered by date DESC
            let entries: [TipEntry] = try await NetworkClient.get("/tips/recent")
            recentEntries = entries
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not load recent shifts."
        }
        isLoading = false
    }

    // MARK: - Delete

    func delete(id: Int) async throws {
        try await NetworkClient.delete("/tips/\(id)")
        recentEntries.removeAll { $0.id == id }
    }

    // MARK: - Update

    func update(id: Int, request: TipEntryRequest) async throws -> TipEntry {
        let updated: TipEntry = try await NetworkClient.put("/tips/\(id)", body: request)
        if let idx = recentEntries.firstIndex(where: { $0.id == id }) {
            recentEntries[idx] = updated
        }
        return updated
    }
}
