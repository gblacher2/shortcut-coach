import Foundation

public struct SupportedApp: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let bundleIdentifier: String?
    public let aliases: [String]
    public let symbolName: String

    public init(
        id: String,
        name: String,
        bundleIdentifier: String? = nil,
        aliases: [String] = [],
        symbolName: String = "macwindow"
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.aliases = aliases
        self.symbolName = symbolName
    }

    public static let launchApps: [SupportedApp] = [
        SupportedApp(id: "chrome", name: "Google Chrome", bundleIdentifier: "com.google.Chrome", aliases: ["Chrome", "browser"], symbolName: "globe"),
        SupportedApp(id: "chatgpt", name: "ChatGPT", bundleIdentifier: "com.openai.chat", aliases: ["ChatGPT for macOS", "OpenAI"], symbolName: "bubble.left.and.bubble.right"),
        SupportedApp(id: "antigravity", name: "Antigravity", bundleIdentifier: "com.google.antigravity", aliases: ["IDE", "editor"], symbolName: "chevron.left.forwardslash.chevron.right"),
        SupportedApp(id: "pages", name: "Pages", bundleIdentifier: "com.apple.iWork.Pages", aliases: ["Apple Pages", "word processor"], symbolName: "doc.text"),
        SupportedApp(id: "finder", name: "Finder", bundleIdentifier: "com.apple.finder", aliases: ["files"], symbolName: "folder"),
        SupportedApp(id: "spotify", name: "Spotify", bundleIdentifier: "com.spotify.client", aliases: ["music"], symbolName: "music.note"),
        SupportedApp(id: "whatsapp", name: "WhatsApp", bundleIdentifier: "net.whatsapp.WhatsApp", aliases: ["messages", "chat"], symbolName: "message"),
        SupportedApp(id: "preview", name: "Preview", bundleIdentifier: "com.apple.Preview", aliases: ["PDF", "images"], symbolName: "doc.richtext"),
        SupportedApp(id: "mail", name: "Apple Mail", bundleIdentifier: "com.apple.mail", aliases: ["Mail", "email"], symbolName: "envelope")
    ]

    public static func app(withID id: String) -> SupportedApp? {
        launchApps.first { $0.id == id }
    }
}
