import js from '@eslint/js';
import globals from 'globals';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';
import tseslint from 'typescript-eslint';
import { defineConfig, globalIgnores } from 'eslint/config';

export default defineConfig([
  globalIgnores(['dist', 'release', 'coverage', 'node_modules']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      js.configs.recommended,
      tseslint.configs.recommended,
      reactHooks.configs.flat['recommended-latest'],
      reactRefresh.configs.vite,
    ],
    languageOptions: { globals: { ...globals.browser, chrome: 'readonly' } },
    rules: {
      // A FAP save must stay a human action. The content adapter may only toggle radios; any
      // programmatic submit/click is a review-blocking defect (see docs/decisions.md D-002).
      'no-restricted-properties': [
        'error',
        { property: 'requestSubmit', message: 'Extension must never submit a FAP form.' },
        { property: 'submit', message: 'Extension must never submit a FAP form.' },
      ],
    },
  },
  {
    files: ['src/components/ui/**'],
    rules: { 'react-refresh/only-export-components': 'off' },
  },
  {
    files: ['scripts/**/*.mjs', '*.config.*'],
    languageOptions: { globals: globals.node },
  },
]);
