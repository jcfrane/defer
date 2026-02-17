import Foundation

struct HomePendingDestructiveAction: Identifiable {
    enum ActionType {
        case markFailed
        case cancel
        case delete
    }

    let id = UUID()
    let action: ActionType
    let item: DeferItem

    var title: String {
        switch action {
        case .markFailed: return "Mark as failed?"
        case .cancel: return "Cancel this defer?"
        case .delete: return "Delete this defer?"
        }
    }

    var message: String {
        switch action {
        case .markFailed:
            return "This will stop the defer and reset momentum."
        case .cancel:
            return "You can still view this in your records if needed."
        case .delete:
            return "This permanently removes the defer and related records."
        }
    }

    var confirmTitle: String {
        switch action {
        case .markFailed: return "Mark Failed"
        case .cancel: return "Cancel Defer"
        case .delete: return "Delete"
        }
    }
}
