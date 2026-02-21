import Foundation

enum HomeActionToastKind: Equatable {
    case urgeLogged
    case fallbackUsed

    var title: String {
        switch self {
        case .urgeLogged:
            return "Urge logged"
        case .fallbackUsed:
            return "Fallback used"
        }
    }

    var detail: String {
        switch self {
        case .urgeLogged:
            return "Moment captured. Keep deferring."
        case .fallbackUsed:
            return "Great redirect under pressure."
        }
    }

    var icon: String {
        switch self {
        case .urgeLogged:
            return "waveform.path.ecg"
        case .fallbackUsed:
            return "shield.checkered"
        }
    }
}

struct HomeActionToast: Identifiable, Equatable {
    let id: UUID
    let kind: HomeActionToastKind

    init(id: UUID = UUID(), kind: HomeActionToastKind) {
        self.id = id
        self.kind = kind
    }
}
