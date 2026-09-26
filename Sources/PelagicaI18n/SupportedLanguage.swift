import Foundation

public struct SupportedLanguage: Codable, Hashable, Sendable, Identifiable {
    /// BCP 47 language code, also the directory name under locales/
    public let code: String
    /// Name of the language in that language
    public let label: String
    /// ISO 3166-1 alpha-2 country code for picking a flag
    public let country: String

    public var id: String { code }
}
