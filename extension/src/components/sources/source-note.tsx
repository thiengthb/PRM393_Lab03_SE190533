import type { ReactNode } from 'react';

export function SourceNote({ children }: Readonly<{ children: ReactNode }>) {
  return <p className="rounded-lg bg-muted px-3 py-2 text-xs text-muted-foreground">{children}</p>;
}
