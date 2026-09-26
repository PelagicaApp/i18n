/// A piece of a translation that may contain `<tag>…</tag>` markup, which the
/// web app renders through react-i18next's `<Trans components={…}>`.
public enum TaggedSegment: Equatable, Sendable {
    case text(String)
    case tag(name: String, content: String)
}

public enum TaggedText {
    public static func parse(_ string: String) -> [TaggedSegment] {
        var segments: [TaggedSegment] = []
        var rest = Substring(string)
        var text = ""

        while let open = rest.range(of: "<") {
            text += rest[..<open.lowerBound]
            let afterOpen = rest[open.upperBound...]
            guard let close = afterOpen.range(of: ">") else {
                rest = rest[open.lowerBound...]
                break
            }
            let name = afterOpen[..<close.lowerBound]
            let body = afterOpen[close.upperBound...]
            if !name.isEmpty, name.allSatisfy({ $0.isLetter || $0.isNumber }),
               let end = body.range(of: "</\(name)>") {
                if !text.isEmpty { segments.append(.text(text)); text = "" }
                segments.append(.tag(name: String(name), content: String(body[..<end.lowerBound])))
                rest = body[end.upperBound...]
            } else {
                text += "<"
                rest = afterOpen
            }
        }
        text += rest
        if !text.isEmpty { segments.append(.text(text)) }
        return segments
    }

    public static func strip(_ string: String) -> String {
        parse(string).map {
            switch $0 {
            case .text(let s): return s
            case .tag(_, let content): return content
            }
        }.joined()
    }
}
