import fs from 'node:fs';
import path from 'node:path';

export const ROOT = path.resolve(import.meta.dirname, '..');
export const LOCALES_DIR = path.join(ROOT, 'locales');
export const REFERENCE_LANGUAGE = 'en';
export const PLURAL_CATEGORIES = ['zero', 'one', 'two', 'few', 'many', 'other'] as const;

export interface LanguageMeta {
    code: string;
    label: string;
    country: string;
}

export function readLanguageMeta(): LanguageMeta[] {
    return JSON.parse(fs.readFileSync(path.join(LOCALES_DIR, 'languages.json'), 'utf8'));
}

/** Language codes that have a directory under locales/ */
export function listLanguageDirs(): string[] {
    return fs
        .readdirSync(LOCALES_DIR, { withFileTypes: true })
        .filter((e) => e.isDirectory())
        .map((e) => e.name)
        .sort();
}

export function listNamespaces(language: string): string[] {
    return fs
        .readdirSync(path.join(LOCALES_DIR, language))
        .filter((f) => f.endsWith('.json'))
        .map((f) => f.slice(0, -'.json'.length))
        .sort();
}

/** Flattens nested objects into dot-separated keys, matching i18next's default keySeparator */
export function flatten(obj: Record<string, unknown>, prefix = ''): Map<string, unknown> {
    const out = new Map<string, unknown>();
    for (const [k, v] of Object.entries(obj)) {
        const key = prefix ? `${prefix}.${k}` : k;
        if (v !== null && typeof v === 'object' && !Array.isArray(v)) {
            for (const [nk, nv] of flatten(v as Record<string, unknown>, key)) out.set(nk, nv);
        } else {
            out.set(key, v);
        }
    }
    return out;
}

export function requiredPluralCategories(language: string): string[] {
    const rules = new Intl.PluralRules(language);
    const found = new Set<string>(['other']);
    for (const n of pluralSampleNumbers()) found.add(rules.select(n));
    return PLURAL_CATEGORIES.filter((c) => found.has(c));
}

export function pluralSampleNumbers(): number[] {
    const nums: number[] = [];
    for (let n = 0; n <= 200; n++) nums.push(n);
    nums.push(1000, 1001, 1002, 1005, 1011, 1022, 1_000_000, 2_000_000, 1_000_001, 1_500_000);
    return nums;
}

const PLURAL_SUFFIX = new RegExp(`^(.+)_(${PLURAL_CATEGORIES.join('|')})$`);

/** Returns the base key if `key` ends in a CLDR plural suffix. */
export function pluralBase(key: string): string | null {
    return key.match(PLURAL_SUFFIX)?.[1] ?? null;
}
