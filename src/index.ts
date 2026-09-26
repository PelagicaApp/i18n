import { languages, namespaces, resources } from './resources';
import type { Language, Namespace } from './resources';

export { languages, namespaces, resources };
export type {
    DefaultResources,
    Language,
    Namespace,
    Resources,
    TranslationTree,
} from './resources';
export * from './languages';

export const FALLBACK_LANGUAGE: Language = 'en';
export const DEFAULT_NAMESPACE: Namespace = 'common';

/**
 * i18next init options that every Pelagica client should share
 */
export const i18nextOptions = {
    resources,
    fallbackLng: FALLBACK_LANGUAGE,
    ns: namespaces,
    defaultNS: DEFAULT_NAMESPACE,
    fallbackNS: DEFAULT_NAMESPACE,
    interpolation: { escapeValue: false, formatSeparator: ',' },
};
