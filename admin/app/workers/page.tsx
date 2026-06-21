import Link from 'next/link';
import { formatDistanceToNow } from 'date-fns';
import { BadgeCheck, Clock } from 'lucide-react';

import { AdminShell } from '../components/admin-shell';
import { EmptyState, InfoTile } from '../components/admin-ui';
import { getWorkers, type WorkerStatus } from '@/lib/admin-data';

export const dynamic = 'force-dynamic';

const statuses: Array<{ label: string; value?: WorkerStatus }> = [
  { label: 'All' },
  { label: 'Pending', value: 'pending' },
  { label: 'Approved', value: 'approved' },
  { label: 'Rejected', value: 'rejected' },
  { label: 'Suspended', value: 'suspended' },
];

export default async function WorkersPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: WorkerStatus }>;
}) {
  const { status } = await searchParams;
  const activeStatus = statuses.some((item) => item.value === status) ? status : undefined;
  const workers = await getWorkers(activeStatus);

  return (
    <AdminShell>
      <div className="flex flex-col gap-4 rounded-lg border border-slate-200 bg-white p-6 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <p className="text-sm font-medium uppercase tracking-wide text-brand-700">Worker verification</p>
          <h2 className="mt-2 text-3xl font-semibold text-slate-950">Health worker queue</h2>
          <p className="mt-2 max-w-2xl text-slate-600">
            Review identity, qualification, documents, service coverage, and pricing before approving access.
          </p>
        </div>
        <div className="flex flex-wrap gap-2" aria-label="Worker status filters">
          {statuses.map((item) => (
            <Link
              className={`rounded-md px-3 py-2 text-sm font-medium ${
                activeStatus === item.value
                  ? 'bg-brand-700 text-white'
                  : 'border border-slate-200 text-slate-700 hover:bg-slate-100'
              }`}
              href={item.value ? `/workers?status=${item.value}` : '/workers'}
              key={item.label}
            >
              {item.label}
            </Link>
          ))}
        </div>
      </div>

      <div className="mt-6 overflow-hidden rounded-lg border border-slate-200 bg-white">
        {workers.length === 0 ? (
          <EmptyState
            title="No workers found"
            description="New health worker submissions will appear here."
          />
        ) : (
          <div className="divide-y divide-slate-200">
            {workers.map((worker) => (
              <Link className="block p-5 hover:bg-slate-50" href={`/workers/${worker.id}`} key={worker.id}>
                <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <h3 className="min-w-0 break-words text-lg font-semibold text-slate-950">
                        {worker.profiles?.full_name ?? 'Unnamed worker'}
                      </h3>
                      <StatusBadge status={worker.verification_status} />
                    </div>
                    <p className="mt-1 text-sm text-slate-600">
                      {labelize(worker.worker_type)} in {worker.city}
                      {worker.service_area ? `, ${worker.service_area}` : ''}
                    </p>
                    <p className="mt-1 text-sm text-slate-500">
                      {worker.qualification} - {worker.experience_years ?? 0} years experience
                    </p>
                  </div>
                  <div className="grid w-full grid-cols-1 gap-3 text-sm min-[420px]:grid-cols-3 md:w-auto md:min-w-80">
                    <InfoTile label="Documents" value={worker.worker_documents.length.toString()} />
                    <InfoTile label="Services" value={worker.worker_services.length.toString()} />
                    <InfoTile
                      label="Submitted"
                      value={formatDistanceToNow(new Date(worker.created_at), { addSuffix: true })}
                    />
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>
    </AdminShell>
  );
}

function StatusBadge({ status }: { status: WorkerStatus }) {
  const styles = {
    pending: 'bg-amber-50 text-amber-800',
    approved: 'bg-emerald-50 text-emerald-800',
    rejected: 'bg-rose-50 text-rose-800',
    suspended: 'bg-slate-100 text-slate-700',
  };
  const Icon = status === 'approved' ? BadgeCheck : Clock;

  return (
    <span className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-medium ${styles[status]}`}>
      <Icon className="h-3 w-3" />
      {labelize(status)}
    </span>
  );
}

function labelize(value: string) {
  return value.replaceAll('_', ' ').replace(/\b\w/g, (match) => match.toUpperCase());
}
