import { parseConfig } from './env-config';

export const config = parseConfig(import.meta.env);
