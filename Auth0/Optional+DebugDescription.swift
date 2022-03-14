import Foundation

extension Optional {

    var debugDescription: String {
        switch self {
        case .none: return "nil"
        case .some(let value): return String(describing: value)
        }
    }

}
