# Pelagica i18n

Translations shared by every Pelagica client: web, desktop, Tizen, and webOS through npm, and Apple platforms through Swift Package Manager. Both packages read the same files in [`locales/`](locales).

## Layout

```
locales/<lang>/<namespace>.json   source of truth (en is the reference language)
locales/languages.json            supported languages: code, native label, flag country
src/                              npm package (src/resources.ts is generated)
scripts/                          generator, validator, plural fixtures
Sources/PelagicaI18n/             Swift package (bundles locales/ directly)
Tests/PelagicaI18nTests/          Swift tests
```

`Package.swift` sits at the repo root because SPM can only resolve a package from the root of a git repository.

The Swift target is rooted at the repo (`path: "."`) so it can bundle `locales/` without a symlink. Older toolchains copy a symlink into the bundle as-is, which breaks it. When you add a new top-level file or folder, add it to `exclude` in `Package.swift`, or SPM warns about unhandled files.

## Writing translations

- Strings use i18next syntax: `{{variable}}` for interpolation and `<tag>…</tag>` for markup rendered with `<Trans>`.
- Plurals use i18next v4 / CLDR suffixes. Add every form the language needs:

  | Language           | Forms                                |
  | ------------------ | ------------------------------------ |
  | en, de, sv         | `_one`, `_other`                     |
  | es, fr, it, pt     | `_one`, `_many` (millions), `_other` |
  | pl                 | `_one`, `_few`, `_many`, `_other`    |
  | ro                 | `_one`, `_few`, `_other`             |
  | ja, vi             | `_other`                             |

  In code, always call the base key with a count: `t('season_count', { count })`. i18next and the Swift `Localizer` pick the form.
- Missing keys fall back to English. `pnpm validate` lists how many keys each language is missing.

### Adding a language

1. Add `locales/<code>/` with any namespaces you've translated.
2. Add an entry to `locales/languages.json`.
3. Run `pnpm generate:fixtures`. If the language has plural rules the Swift side doesn't know yet, `swift test` fails until you add them to `Sources/PelagicaI18n/PluralRules.swift`.

## JavaScript

```sh
pnpm add @pelagica/i18n
```

```ts
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import { i18nextOptions, SUPPORTED_LANGUAGES, type DefaultResources } from '@pelagica/i18n';

i18n.use(initReactI18next).init({
    ...i18nextOptions,
    react: { useSuspense: false },
});

declare module 'i18next' {
    interface CustomTypeOptions {
        defaultNS: 'common';
        resources: DefaultResources;
    }
}
```

The package doesn't use `import.meta.glob`. It bundles static imports that `scripts/generate-resources.ts` generates, so it works with any bundler, and the output targets ES2015 for older TV engines. The raw JSON is also published as `@pelagica/i18n/locales/*`.

## Swift

```swift
.package(url: "https://github.com/PelagicaApp/i18n.git", from: "1.0.0")
```

```swift
import PelagicaI18n

let l = try Localizer()                          // best match for Locale.preferredLanguages
l.t("cancel")                                    // "Cancel"
l.t("music:tracks_count", count: 3)              // "3 tracks"
l.t("ends_at", ["date": "20:15"])                // "Ends at 20:15"
TaggedText.parse(l.t("stats_consent_message"))   // [.text(…), .tag(name: "anchor", content: …), …]
```

`Localizer` follows the same lookup rules as the web app's i18next setup: namespace, then `common`, then English; `_zero`/`_<category>`/bare key for plurals; unknown placeholders left in place.

## Development

```sh
pnpm install
pnpm validate      # key parity, plural forms, placeholders, tags (--verbose lists missing keys)
pnpm build         # generate src/resources.ts and bundle to dist/
swift test
```

## Releasing

Both packages share one version and one tag.

1. Bump `version` in `package.json` and commit.
2. Tag and push:

   ```sh
   git tag v1.4.0 && git push origin v1.4.0
   ```

   The release workflow runs CI, publishes to npm (trusted publishing), and creates a GitHub release. SPM consumers resolve the tag directly.
