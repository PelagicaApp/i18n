import Foundation

public enum LocalizerError: Error, Equatable {
    case resourcesNotFound
    case unsupportedLanguage(String)
}

/// Looks up translations from the shared locales/ JSON the same way the web
/// app's i18next setup does:
///
/// - keys can be namespaced as `"ns:key"`; nested JSON keys use dots
/// - lookup tries the namespace, then `common`, in the chosen language, then English
/// - with a count, `key_zero` (count 0), then `key_<plural category>`, then `key`
/// - `{{name}}` and `{{name, format}}` are replaced from `values`; `count` is filled in automatically
/// - a missing key returns the key itself
public struct Localizer: Sendable {
    public static let fallbackLanguage = "en"
    public static let defaultNamespace = "common"

    public let language: String

    /// language -> namespace -> flattened key -> value
    private let tables: [String: [String: [String: String]]]
    private let lookupLanguages: [String]

    /// - Parameter language: A supported language code. Regional variants
    ///   (`pt-BR`) resolve to their base language (`pt`).
    public init(language: String) throws {
        let supported = try Self.supportedLanguages().map(\.code)
        let resolved = supported.contains(language) ? language : PluralRules.baseLanguage(language)
        guard supported.contains(resolved) else { throw LocalizerError.unsupportedLanguage(language) }

        self.language = resolved
        self.lookupLanguages = resolved == Self.fallbackLanguage ? [resolved] : [resolved, Self.fallbackLanguage]

        let root = try Self.resourcesURL()
        var tables: [String: [String: [String: String]]] = [:]
        for lang in lookupLanguages {
            tables[lang] = try Self.loadLanguage(at: root.appendingPathComponent(lang, isDirectory: true))
        }
        self.tables = tables
    }

    /// Picks the best supported language for the user's preferred languages,
    /// falling back to English.
    public init(preferredLanguages: [String] = Locale.preferredLanguages) throws {
        let supported = try Self.supportedLanguages().map(\.code)
        let match = preferredLanguages.lazy.compactMap { preferred -> String? in
            if supported.contains(preferred) { return preferred }
            let base = PluralRules.baseLanguage(preferred)
            return supported.contains(base) ? base : nil
        }.first
        try self.init(language: match ?? Self.fallbackLanguage)
    }

    public static func supportedLanguages() throws -> [SupportedLanguage] {
        let url = try resourcesURL().appendingPathComponent("languages.json")
        return try JSONDecoder().decode([SupportedLanguage].self, from: Data(contentsOf: url))
    }

    /// Translates `key`, which may be prefixed with a namespace (`"music:tracks_count"`).
    public func t(
        _ key: String,
        namespace: String = Localizer.defaultNamespace,
        count: Int? = nil,
        _ values: [String: CustomStringConvertible] = [:]
    ) -> String {
        var namespace = namespace
        var key = key
        if let colon = key.firstIndex(of: ":") {
            namespace = String(key[..<colon])
            key = String(key[key.index(after: colon)...])
        }

        var values = values
        if let count, values["count"] == nil { values["count"] = count }

        let namespaces = namespace == Self.defaultNamespace ? [namespace] : [namespace, Self.defaultNamespace]
        for ns in namespaces {
            for lang in lookupLanguages {
                for candidate in candidateKeys(key, count: count, language: lang) {
                    if let value = tables[lang]?[ns]?[candidate] {
                        return interpolate(value, values)
                    }
                }
            }
        }
        return key
    }

    private func candidateKeys(_ key: String, count: Int?, language: String) -> [String] {
        guard let count else { return [key] }
        var keys: [String] = []
        if count == 0 { keys.append("\(key)_zero") }
        keys.append("\(key)_\(PluralRules.category(for: count, language: language).rawValue)")
        keys.append(key)
        return keys
    }

    private func interpolate(_ string: String, _ values: [String: CustomStringConvertible]) -> String {
        guard string.contains("{{") else { return string }
        var result = ""
        var rest = Substring(string)
        while let open = rest.range(of: "{{"), let close = rest[open.upperBound...].range(of: "}}") {
            result += rest[..<open.lowerBound]
            let inner = rest[open.upperBound..<close.lowerBound]
            let name = inner.split(separator: ",", maxSplits: 1).first?.trimmingCharacters(in: .whitespaces) ?? ""
            if let value = values[name] {
                result += value.description
            } else {
                result += rest[open.lowerBound..<close.upperBound]
            }
            rest = rest[close.upperBound...]
        }
        return result + rest
    }

    private static func resourcesURL() throws -> URL {
        guard let url = Bundle.module.url(forResource: "locales", withExtension: nil) else {
            throw LocalizerError.resourcesNotFound
        }
        return url
    }

    private static func loadLanguage(at directory: URL) throws -> [String: [String: String]] {
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        var namespaces: [String: [String: String]] = [:]
        for file in files where file.pathExtension == "json" {
            let object = try JSONSerialization.jsonObject(with: Data(contentsOf: file))
            var flat: [String: String] = [:]
            flatten(object, prefix: "", into: &flat)
            namespaces[file.deletingPathExtension().lastPathComponent] = flat
        }
        return namespaces
    }

    private static func flatten(_ object: Any, prefix: String, into result: inout [String: String]) {
        if let dict = object as? [String: Any] {
            for (key, value) in dict {
                flatten(value, prefix: prefix.isEmpty ? key : "\(prefix).\(key)", into: &result)
            }
        } else if let string = object as? String {
            result[prefix] = string
        }
    }
}
