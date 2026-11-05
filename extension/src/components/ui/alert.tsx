import * as React from 'react';
import { cva, type VariantProps } from 'class-variance-authority';

import { cn } from '@/lib/utils';

const alertVariants = cva(
  'grid w-full grid-cols-[auto_1fr] items-start gap-x-2 gap-y-0.5 rounded-lg border px-3 py-2 text-sm [&>svg]:mt-0.5 [&>svg]:size-4 [&>svg]:shrink-0',
  {
    variants: {
      variant: {
        default: 'border-primary-soft-edge bg-primary-soft text-on-primary-soft',
        success: 'border-ok/30 bg-ok-soft text-foreground [&>svg]:text-ok',
        destructive: 'border-alert/30 bg-alert-soft text-foreground [&>svg]:text-alert',
        warning: 'border-warn/40 bg-warn-soft text-foreground [&>svg]:text-warn',
      },
    },
    defaultVariants: { variant: 'default' },
  },
);

function Alert({
  className,
  variant,
  ...props
}: React.ComponentProps<'div'> & VariantProps<typeof alertVariants>) {
  return (
    <div
      data-slot="alert"
      role={variant === 'destructive' ? 'alert' : 'status'}
      className={cn(alertVariants({ variant }), className)}
      {...props}
    />
  );
}

function AlertDescription({ className, ...props }: React.ComponentProps<'div'>) {
  return (
    <div
      data-slot="alert-description"
      className={cn('col-start-2 min-w-0 text-sm break-words', className)}
      {...props}
    />
  );
}

export { Alert, AlertDescription };
