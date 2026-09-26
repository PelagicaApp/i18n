import fs from 'node:fs';
import path from 'node:path';
import { ROOT, listLanguageDirs, pluralSampleNumbers } from './lib.ts';

const fixtures: Record<string, Record<string, string>> = {};
for (const lang of listLanguageDirs()) {
    const rules = new Intl.PluralRules(lang);
    fixtures[lang] = Object.fromEntries(
        pluralSampleNumbers().map((n) => [String(n), rules.select(n)])
    );
}

const out = path.join(ROOT, 'Tests', 'PelagicaI18nTests', 'Fixtures', 'plural-rules.json');
fs.writeFileSync(out, JSON.stringify(fixtures, null, 2) + '\n');
console.log(`Wrote ${path.relative(ROOT, out)}`);
