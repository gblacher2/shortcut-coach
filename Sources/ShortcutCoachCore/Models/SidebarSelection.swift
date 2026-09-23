import Foundation

public enum SidebarSelection: Hashable, Sendable {
    case all
    case favourites
    case toLearn
    case recentlyViewed
    case myMacSystem
    case myMacPersonal
    case app(String)
    case tag(String)
    case category(String)
    case collection(String)
}
