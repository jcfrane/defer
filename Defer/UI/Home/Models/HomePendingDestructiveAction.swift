import Foundation

struct HomePendingDestructiveAction: Identifiable {
    enum ActionType {
        case markGaveIn
        case cancel
        case delete
    }

    let id = UUID()
    let action: ActionType
    let item: DeferItem

    var title: String {
        switch action {
        case .markGaveIn:
            return "Record gave in outcome?"
        case .cancel:
            return "Cancel this intent?"
        case .delete:
            return "Delete this intent?"
        }
    }

    var message: String {
        switch action {
        case .markGaveIn:
            return "This resolves the intent as a reactive choice and moves it to history."
        case .cancel:
            return "This closes the intent without a decision outcome."
        case .delete:
            return "This permanently removes the intent and related records."
        }
    }

    var confirmTitle: String {
        switch action {
        case .markGaveIn:
            return "Record Outcome"
        case .cancel:
            return "Cancel Intent"
        case .delete:
            return "Delete"
        }
    }
}
