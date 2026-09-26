public enum PluralCategory: String, CaseIterable, Sendable {
    case zero, one, two, few, many, other
}

public enum PluralRules {
    public static func category(for count: Int, language: String) -> PluralCategory {
        let n = count.magnitude
        switch baseLanguage(language) {
        case "ja", "vi", "zh", "ko", "th", "id":
            return .other
        case "fr":
            if n <= 1 { return .one }
            return isMillions(n) ? .many : .other
        case "pt":
            if n <= 1 { return .one }
            return isMillions(n) ? .many : .other
        case "es", "it", "ca":
            if n == 1 { return .one }
            return isMillions(n) ? .many : .other
        case "pl":
            if n == 1 { return .one }
            let mod10 = n % 10, mod100 = n % 100
            if (2...4).contains(mod10) && !(12...14).contains(mod100) { return .few }
            return .many
        case "ro":
            if n == 1 { return .one }
            if n == 0 || (1...19).contains(n % 100) { return .few }
            return .other
        default:
            // en, de, sv and most other languages
            return n == 1 ? .one : .other
        }
    }

    static func baseLanguage(_ code: String) -> String {
        String(code.lowercased().split(whereSeparator: { $0 == "-" || $0 == "_" }).first ?? "")
    }

    /// CLDR's `e = 0 and i != 0 and i % 1000000 = 0` rule for "many".
    private static func isMillions(_ n: UInt) -> Bool {
        n != 0 && n % 1_000_000 == 0
    }
}
