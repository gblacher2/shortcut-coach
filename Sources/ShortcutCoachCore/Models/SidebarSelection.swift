import Foundation

public enum SidebarSelection: Hashable, Sendable {
    case all
    case favourites
    case toLearn
    case recentlyViewed
    case app(String)
    case tag(String)
    case collection(String)
}
