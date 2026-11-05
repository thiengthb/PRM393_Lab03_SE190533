import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';

import '@/styles/globals.css';

import { App } from './app';

// Follow the OS/browser color scheme live; tokens switch through the `.dark` class (sakubun).
const scheme = matchMedia('(prefers-color-scheme: dark)');
const applyScheme = () => document.documentElement.classList.toggle('dark', scheme.matches);
applyScheme();
scheme.addEventListener('change', applyScheme);

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
