import { cn } from '@/lib/utils';

/**
 * Attendo wordmark, same as BrandWordmark in packages/core/lib/widgets/brand.dart: "attend" in
 * Onest 700 with tight tracking, then the "o" drawn as the brand ring with a centre dot. The ring
 * sits on the baseline at 0.52em, like the app. Colour follows currentColor for the text and
 * --primary for the ring.
 */
export function BrandWordmark({ className }: { className?: string }) {
  return (
    <span
      role="img"
      aria-label="Attendo"
      className={cn(
        'inline-flex items-baseline font-bold leading-none tracking-[-0.045em] text-foreground',
        className,
      )}
    >
      <span aria-hidden>attend</span>
      <svg
        aria-hidden
        viewBox="0 0 40 40"
        className="ml-[0.02em] size-[0.52em] translate-y-[0.015em] text-primary"
      >
        <circle cx="20" cy="20" r="15.5" fill="none" stroke="currentColor" strokeWidth="7.5" />
        <circle cx="20" cy="20" r="5" fill="currentColor" />
      </svg>
    </span>
  );
}
