import languageList from '../locales/languages.json';

export interface SupportedLanguage {
    /** BCP 47 language code, also the directory name under locales/ */
    code: string;
    /** Name of the language in that language */
    label: string;
    /** ISO 3166-1 alpha-2 country code for picking a flag */
    country: string;
}

export const SUPPORTED_LANGUAGES: readonly SupportedLanguage[] = languageList;
