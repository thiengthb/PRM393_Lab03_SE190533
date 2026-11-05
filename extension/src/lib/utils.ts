import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function errorMessage(error: unknown, fallback: string): string {
  if (error instanceof Error && error.message && error.name !== 'ZodError') return error.message;
  return fallback;
}
