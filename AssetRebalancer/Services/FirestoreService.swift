import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Firestore Service
class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private var userID: String? {
        Auth.auth().currentUser?.uid
    }

    private func userDocument() -> DocumentReference? {
        guard let uid = userID else { return nil }
        return db.collection("users").document(uid)
    }

    // MARK: - Assets CRUD

    func fetchAssets() async throws -> [Asset] {
        guard let doc = userDocument() else {
            throw FirestoreError.notAuthenticated
        }

        let snapshot = try await doc.collection("assets").getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: Asset.self)
        }
    }

    func saveAsset(_ asset: Asset) async throws {
        guard let doc = userDocument() else {
            throw FirestoreError.notAuthenticated
        }

        try doc.collection("assets").document(asset.id).setData(from: asset)
    }

    func deleteAsset(_ assetID: String) async throws {
        guard let doc = userDocument() else {
            throw FirestoreError.notAuthenticated
        }

        try await doc.collection("assets").document(assetID).delete()
    }

    // MARK: - Target Allocation

    func fetchTargetAllocation() async throws -> TargetAllocation {
        guard let doc = userDocument() else {
            throw FirestoreError.notAuthenticated
        }

        let snapshot = try await doc.getDocument()
        if let data = snapshot.data(),
           let target = data["targetAllocation"] as? [String: Double] {
            return TargetAllocation(
                stock: target["stock"] ?? 60,
                bond: target["bond"] ?? 30,
                cash: target["cash"] ?? 10
            )
        }
        return TargetAllocation()
    }

    func saveTargetAllocation(_ target: TargetAllocation) async throws {
        guard let doc = userDocument() else {
            throw FirestoreError.notAuthenticated
        }

        try await doc.setData([
            "targetAllocation": [
                "stock": target.stock,
                "bond": target.bond,
                "cash": target.cash
            ]
        ], merge: true)
    }

    // MARK: - Settings

    func fetchDeviationThreshold() async throws -> Double {
        guard let doc = userDocument() else {
            throw FirestoreError.notAuthenticated
        }

        let snapshot = try await doc.getDocument()
        return snapshot.data()?["deviationThreshold"] as? Double ?? 5.0
    }

    func saveDeviationThreshold(_ threshold: Double) async throws {
        guard let doc = userDocument() else {
            throw FirestoreError.notAuthenticated
        }

        try await doc.setData(["deviationThreshold": threshold], merge: true)
    }
}

// MARK: - Errors
enum FirestoreError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        }
    }
}
