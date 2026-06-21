import {
  Clock,
  FileClock,
  ShieldCheck,
  UserRound,
} from 'lucide-react';

import { AdminShell } from '../components/admin-shell';
import { EmptyState, MetricCard } from '../components/admin-ui';
import { getAdminAuditTimeline } from '@/lib/admin-data';

export const dynamic = 'force-dynamic';

export default async function AuditLogsPage() {
  const events = await getAdminAuditTimeline();
  const uniqueOrders = new Set(
    events.map((event) => event.orderId).filter(Boolean),
  ).size;
  const actorCount = new Set(
    events.map((event) => event.actorUserId).filter(Boolean),
  ).size;
  const adminActionCount = events.filter(
    (event) => event.source === 'admin_audit_log',
  ).length;

  return (
    <AdminShell>
      <div className="rounded-lg border border-slate-200 bg-white p-6">
        <p className="text-sm font-medium uppercase tracking-wide text-brand-700">Traceability</p>
        <h2 className="mt-2 text-3xl font-semibold text-slate-950">Audit logs</h2>
        <p className="mt-2 max-w-2xl text-slate-600">
          Review operational order events and privileged admin actions with compact, sanitized metadata for safety,
          support, and dispute follow-up.
        </p>
      </div>

      <div className="mt-6 grid gap-4 md:grid-cols-4">
        <MetricCard icon={FileClock} label="Recent events" value={events.length.toString()} />
        <MetricCard icon={ShieldCheck} label="Admin actions" value={adminActionCount.toString()} />
        <MetricCard icon={Clock} label="Orders traced" value={uniqueOrders.toString()} />
        <MetricCard icon={UserRound} label="Known actors" value={actorCount.toString()} />
      </div>

      <div className="mt-6 overflow-hidden rounded-lg border border-slate-200 bg-white">
        {events.length === 0 ? (
          <EmptyState
            title="No audit events found"
            description="Order events and privileged admin actions will appear here after activity is logged."
          />
        ) : (
          <div className="divide-y divide-slate-200">
            {events.map((event) => {
              return (
                <article className="p-5" key={event.id}>
                  <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <h3 className="min-w-0 break-words text-lg font-semibold text-slate-950">
                          {labelize(event.title)}
                        </h3>
                        <span className={sourceBadgeClass(event.source)}>
                          {event.source === 'admin_audit_log' ? 'Admin action' : 'Order event'}
                        </span>
                        <span className="rounded-full bg-slate-100 px-2 py-1 text-xs font-medium text-slate-700">
                          {labelize(event.category)}
                        </span>
                        {event.orderStatus ? (
                          <span className="rounded-full bg-slate-100 px-2 py-1 text-xs font-medium text-slate-700">
                            {labelize(event.orderStatus)}
                          </span>
                        ) : null}
                      </div>
                      <p className="mt-2 break-words text-sm text-slate-600">
                        Actor: {event.actorName} - {event.actorRole}
                      </p>
                      <p className="mt-1 text-sm text-slate-500">
                        {new Date(event.created_at).toLocaleString()}
                        {event.orderId ? ` - Order ${event.orderId.slice(0, 8)}` : null}
                      </p>
                      {event.serviceName || event.locationLabel ? (
                        <p className="mt-3 max-w-2xl break-words text-sm text-slate-700">
                          {event.serviceName ?? 'Service'}
                          {event.locationLabel ? ` at ${event.locationLabel}` : null}
                        </p>
                      ) : null}
                    </div>

                    <SafeMetadata items={event.metadata} />
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </div>
    </AdminShell>
  );
}

function SafeMetadata({
  items,
}: {
  items: {
    label: string;
    value: string;
  }[];
}) {
  if (items.length === 0) {
    return (
      <div className="w-full rounded-md bg-slate-50 p-3 text-xs text-slate-500 lg:w-72">
        No safe metadata to display
      </div>
    );
  }

  return (
    <dl className="grid w-full max-w-xl grid-cols-1 gap-2 rounded-md bg-slate-50 p-3 text-xs sm:grid-cols-2 lg:w-80">
      {items.map((item) => (
        <div className="min-w-0" key={`${item.label}:${item.value}`}>
          <dt className="font-medium text-slate-500">{item.label}</dt>
          <dd className="mt-1 break-words font-semibold text-slate-900" title={item.value}>
            {item.value}
          </dd>
        </div>
      ))}
    </dl>
  );
}

function labelize(value: string) {
  return value.replaceAll('_', ' ').replace(/\b\w/g, (match) => match.toUpperCase());
}

function sourceBadgeClass(source: 'order_event' | 'admin_audit_log') {
  return source === 'admin_audit_log'
    ? 'rounded-full bg-emerald-50 px-2 py-1 text-xs font-medium text-emerald-800'
    : 'rounded-full bg-brand-50 px-2 py-1 text-xs font-medium text-brand-800';
}
