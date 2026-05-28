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

    // MARK: - Settings (combined fetch to avoid reading the same document twice)

    func fetchSettings() async throws -> (target: TargetAllocation, threshold: Double) {
        guard let doc = userDocument() else {
            throw FirestoreError.notAuthenticated
        }

        let snapshot = try await doc.getDocument()
        let data = snapshot.data() ?? [:]

        let target: TargetAllocation
        if let t = data["targetAllocation"] as? [String: Double] {
            target = TargetAllocation(stock: t["stock"] ?? 60, bond: t["bond"] ?? 30, cash: t["cash"] ?? 10)
        } else {
            target = TargetAllocation()
        }

        let threshold = data["deviationThreshold"] as? Double ?? 5.0
        return (target, threshold)
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

    func saveDeviationThreshold(_ threshold: Double) async throws {
        guard let doc = userDocument() else {
            throw FirestoreError.notAuthenticated
        }

        try await doc.setData(["deviationThreshold": threshold], merge: true)
    }

    // MARK: - Delete All User Data

    func deleteAllUserData() async throws {
        guard let doc = userDocument() else {
            throw FirestoreError.notAuthenticated
        }

        // Delete all assets in subcollection
        let assetsSnapshot = try await doc.collection("assets").getDocuments()
        for document in assetsSnapshot.documents {
            try await document.reference.delete()
        }

        // Delete user document
        try await doc.delete()
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
