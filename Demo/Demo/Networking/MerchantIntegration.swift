import Foundation

enum MerchantIntegration: String, CaseIterable {
    case direct
    case connectedPath3
    case connectedPath4
    case managedPath
    
    var path: String {
        switch self {
        case .direct:
            return "/direct"
        case .connectedPath3:
            return "/connected_path"
        case .connectedPath4:
            return "/connected_path"
        case .managedPath:
            return "/managed_path"
        }
    }
}
