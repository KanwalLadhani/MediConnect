import type { ComponentType, ReactNode } from 'react';
import { SearchX } from 'lucide-react';

type IconComponent = ComponentType<{ className?: string }>;

export function PageHeader({
  eyebrow,
  title,
  children,
}: {
  eyebrow: string;
  title: string;
  children: ReactNode;
}) {
  return (
    <div className="rounded-lg border border-slate-200 bg-white p-6">
      <p className="text-sm font-medium uppercase tracking-wide text-brand-700">{eyebrow}</p>
      <h2 className="mt-2 text-3xl font-semibold text-slate-950">{title}</h2>
      <div className="mt-2 max-w-2xl text-slate-600">{children}</div>
    </div>
  );
}

export function EmptyState({
  icon: Icon = SearchX,
  title,
  description,
}: {
  icon?: IconComponent;
  title: string;
  description: string;
}) {
  return (
    <div className="flex flex-col items-center px-6 py-14 text-center">
      <Icon className="h-10 w-10 text-slate-400" aria-hidden="true" />
      <h3 className="mt-4 text-lg font-semibold text-slate-950">{title}</h3>
      <p className="mt-1 max-w-md text-sm text-slate-600">{description}</p>
    </div>
  );
}

export function MetricCard({
  icon: Icon,
  label,
  value,
  detail,
}: {
  icon: IconComponent;
  label: string;
  value: string;
  detail?: string;
}) {
  return (
    <article className="rounded-lg border border-slate-200 bg-white p-5">
      <div className="flex min-w-0 items-start justify-between gap-4">
        <Icon className="h-5 w-5 shrink-0 text-brand-700" aria-hidden="true" />
        <span className="min-w-0 break-words text-right text-2xl font-semibold tabular-nums text-slate-950">
          {value}
        </span>
      </div>
      <p className="mt-4 text-sm text-slate-600">{label}</p>
      {detail ? <p className="mt-2 text-xs text-slate-500">{detail}</p> : null}
    </article>
  );
}

export function InfoTile({ label, value }: { label: string; value: string }) {
  return (
    <div className="min-w-0 rounded-md bg-slate-50 px-3 py-2">
      <p className="text-xs text-slate-500">{label}</p>
      <p className="mt-1 break-words font-semibold tabular-nums text-slate-950">{value}</p>
    </div>
  );
}

export function StatusPill({
  children,
  tone = 'neutral',
}: {
  children: ReactNode;
  tone?: 'neutral' | 'success' | 'warning' | 'danger' | 'brand';
}) {
  const className = {
    neutral: 'bg-slate-100 text-slate-700',
    success: 'bg-emerald-50 text-emerald-800',
    warning: 'bg-amber-50 text-amber-800',
    danger: 'bg-rose-50 text-rose-800',
    brand: 'bg-brand-50 text-brand-800',
  }[tone];

  return (
    <span className={`inline-flex max-w-full items-center gap-1 rounded-full px-2 py-1 text-xs font-medium ${className}`}>
      {children}
    </span>
  );
}
