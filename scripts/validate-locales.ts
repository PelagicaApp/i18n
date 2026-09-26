import fs from 'node:fs';
import path from 'node:path';
import {
    LOCALES_DIR,
    REFERENCE_LANGUAGE,
    flatten,
    listLanguageDirs,
    listNamespaces,
    pluralBase,
    readLanguageMeta,
    requiredPluralCategories,
} from './lib.ts';

const strict = process.argv.includes('--strict');
const verbose = strict || process.argv.includes('--verbose');
const errors: string[] = [];
const warnings: string[] = [];
const missingCount = new Map<string, number>();

function load(lang: string, ns: string): Map<string, unknown> | null {
    const file = path.join(LOCALES_DIR, lang, `${ns}.json`);
    try {
        return flatten(JSON.parse(fs.readFileSync(file, 'utf8')));
    } catch (e) {
        errors.push(`${lang}/${ns}.json: ${(e as Error).message}`);
        return null;
    }
}

const vars = (s: string) =>
    new Set([...s.matchAll(/\{\{\s*([^,}\s]+)[^}]*\}\}/g)].map((m) => m[1]));
const tags = (s: string) => new Set([...s.matchAll(/<\/?([a-zA-Z0-9]+)\s*\/?>/g)].map((m) => m[1]));

/** Groups keys into plain keys and plural groups (base -> forms). */
function group(entries: Map<string, unknown>) {
    const plural = new Map<string, Map<string, string>>();
    const plain = new Map<string, string>();
    for (const [key, value] of entries) {
        const base = pluralBase(key);
        const str = String(value);
        if (base) {
            if (!plural.has(base)) plural.set(base, new Map());
            plural.get(base)!.set(key.slice(base.length + 1), str);
        } else {
            plain.set(key, str);
        }
    }
    return { plain, plural };
}

// languages.json <-> locales/ directories
const metaCodes = readLanguageMeta().map((l) => l.code);
const dirs = listLanguageDirs();
for (const d of dirs)
    if (!metaCodes.includes(d)) errors.push(`locales/${d}/ has no entry in languages.json`);
for (const c of metaCodes)
    if (!dirs.includes(c))
        errors.push(`languages.json lists "${c}" but locales/${c}/ does not exist`);

const refNamespaces = listNamespaces(REFERENCE_LANGUAGE);
const reference = new Map(refNamespaces.map((ns) => [ns, load(REFERENCE_LANGUAGE, ns)]));

for (const lang of dirs) {
    const required = requiredPluralCategories(lang);
    const namespaces = listNamespaces(lang);
    const warnMissing = (msg: string, n = 1) => {
        missingCount.set(lang, (missingCount.get(lang) ?? 0) + n);
        if (strict) errors.push(msg);
        else if (verbose) warnings.push(msg);
    };

    for (const ns of namespaces) {
        if (!refNamespaces.includes(ns))
            errors.push(`${lang}/${ns}.json: namespace does not exist in ${REFERENCE_LANGUAGE}`);
    }

    for (const ns of refNamespaces) {
        const refEntries = reference.get(ns);
        if (!refEntries) continue;
        const ref = group(refEntries);
        const where = `${lang}/${ns}.json`;

        if (!namespaces.includes(ns)) {
            if (lang !== REFERENCE_LANGUAGE)
                warnMissing(
                    `${where}: file missing (${ref.plain.size + ref.plural.size} keys)`,
                    ref.plain.size + ref.plural.size
                );
            continue;
        }
        const entries = load(lang, ns);
        if (!entries) continue;

        for (const [key, value] of entries) {
            if (typeof value !== 'string') errors.push(`${where}: "${key}" must be a string`);
            if (/_plural(_|$)/.test(key))
                errors.push(
                    `${where}: "${key}" uses the legacy _plural suffix; use _one/_few/_many/_other`
                );
        }
        const cur = group(entries);

        const checkText = (label: string, text: string, refTexts: string[]) => {
            const refVars = new Set(refTexts.flatMap((t) => [...vars(t)]));
            for (const v of vars(text)) {
                if (!refVars.has(v) && v !== 'count')
                    errors.push(
                        `${where}: "${label}" uses {{${v}}}, which ${REFERENCE_LANGUAGE} does not`
                    );
            }
            const refTags = new Set(refTexts.flatMap((t) => [...tags(t)]));
            const curTags = tags(text);
            for (const t of curTags)
                if (!refTags.has(t))
                    errors.push(
                        `${where}: "${label}" has <${t}>, which ${REFERENCE_LANGUAGE} does not`
                    );
            for (const t of refTags)
                if (!curTags.has(t)) errors.push(`${where}: "${label}" is missing <${t}>`);
        };

        for (const [key, text] of cur.plain) {
            if (ref.plain.has(key)) checkText(key, text, [ref.plain.get(key)!]);
            else if (ref.plural.has(key))
                errors.push(
                    `${where}: "${key}" is a plural key in ${REFERENCE_LANGUAGE}; use ${key}_${required.join(`/_`)}`
                );
            else errors.push(`${where}: "${key}" does not exist in ${REFERENCE_LANGUAGE}`);
        }
        for (const key of ref.plain.keys()) {
            if (!cur.plain.has(key) && !cur.plural.has(key))
                warnMissing(`${where}: "${key}" not translated`);
        }

        for (const [base, forms] of cur.plural) {
            const refForms = ref.plural.get(base);
            if (!refForms) {
                errors.push(
                    `${where}: plural key "${base}_*" does not exist in ${REFERENCE_LANGUAGE}`
                );
                continue;
            }
            const missing = required.filter((c) => !forms.has(c));
            if (missing.length)
                errors.push(
                    `${where}: "${base}" is missing plural forms: ${missing.map((c) => `_${c}`).join(', ')}`
                );
            for (const c of forms.keys()) {
                if (!required.includes(c))
                    warnings.push(`${where}: "${base}_${c}" is never used for ${lang}`);
            }
            for (const [c, text] of forms) checkText(`${base}_${c}`, text, [...refForms.values()]);
        }
        for (const base of ref.plural.keys()) {
            if (!cur.plural.has(base)) warnMissing(`${where}: "${base}" not translated`);
        }
    }
}

for (const w of warnings) console.warn(`warning: ${w}`);
for (const e of errors) console.error(`error: ${e}`);

if (missingCount.size) {
    console.log('\nUntranslated keys (falling back to en):');
    for (const [lang, n] of [...missingCount].sort()) console.log(`  ${lang}: ${n}`);
}
console.log(`\n${errors.length} error(s), ${warnings.length} warning(s)`);
process.exit(errors.length ? 1 : 0);
