import { revalidatePath } from 'next/cache';
import Link from 'next/link';
import { AlertTriangle, CheckCircle2 } from 'lucide-react';

import { AdminShell } from '../components/admin-shell';
import { EmptyState } from '../components/admin-ui';
import { getAdminDisputes, updateDisputeStatus } from '@/lib/admin-data';
import { parseDisputeReviewForm } from '@/lib/admin-dispute-review';

export const dynamic = 'force-dynamic';

const statuses = ['all', 'open', 'reviewing', 'resolved', 'rejected'];

async function reviewDispute(formData: FormData) {
  'use server';

  await updateDisputeStatus(parseDisputeReviewForm(formData, 'reviewing'));
  revalidatePath('/disputes');
}

async function resolveDispute(formData: FormData) {
  'use server';

  await updateDisputeStatus(parseDisputeReviewForm(formData, 'resolved'));
  revalidatePath('/disputes');
}

async function rejectDispute(formData: FormData) {
  'use server';

  await updateDisputeStatus(parseDisputeReviewForm(formData, 'rejected'));
  revalidatePath('/disputes');
}

export default async function DisputesPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  const { status } = await searchParams;
  const activeStatus =
    status && statuses.includes(status) && status !== 'all' ? status : undefined;
  const disputes = await getAdminDisputes(activeStatus);

  return (
    <AdminShell>
      <div className="rounded-lg border border-slate-200 bg-white p-6">
        <p className="text-sm font-medium uppercase tracking-wide text-brand-700">Safety review</p>
        <h2 className="mt-2 text-3xl font-semibold text-slate-950">Disputes</h2>
        <p className="mt-2 max-w-2xl text-slate-600">
          Review reported issues with patient, worker, order, service, and resolution notes.
        </p>
      </div>

      <div className="mt-6 flex flex-wrap gap-2" aria-label="Dispute status filters">
        {statuses.map((item) => (
          <Link
            className={`rounded-md px-3 py-2 text-sm font-medium ${
              (activeStatus ?? 'all') === item
                ? 'bg-brand-700 text-white'
                : 'border border-slate-200 bg-white text-slate-700 hover:bg-slate-100'
            }`}
            href={item === 'all' ? '/disputes' : `/disputes?status=${item}`}
            key={item}
          >
            {labelize(item)}
          </Link>
        ))}
      </div>

      <div className="mt-6 overflow-hidden rounded-lg border border-slate-200 bg-white">
        {disputes.length === 0 ? (
          <EmptyState
            title="No disputes found"
            description="Reported order issues will appear here."
          />
        ) : (
          <div className="divide-y divide-slate-200">
            {disputes.map((dispute) => {
              const order = dispute.orders;
              const request = order?.service_requests;
              return (
                <article className="p-5" key={dispute.id}>
                  <div className="flex flex-col gap-5 xl:flex-row xl:items-start xl:justify-between">
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <AlertTriangle className="h-5 w-5 shrink-0 text-amber-700" aria-hidden="true" />
                        <h3 className="min-w-0 break-words text-lg font-semibold text-slate-950">{dispute.reason}</h3>
                        <span className="rounded-full bg-slate-100 px-2 py-1 text-xs font-medium text-slate-700">
                          {labelize(dispute.status)}
                        </span>
                      </div>
                      <p className="mt-2 break-words text-sm text-slate-600">
                        Reported by {dispute.reporter?.full_name ?? 'User'} - {dispute.reporter?.phone ?? 'No phone'}
                      </p>
                      <p className="mt-2 whitespace-pre-wrap break-words text-sm text-slate-700">
                        {dispute.details ?? 'No extra details provided.'}
                      </p>
                      <div className="mt-4 rounded-md bg-slate-50 p-4 text-sm text-slate-700">
                        <p className="font-semibold text-slate-950">
                          {request?.service_categories?.name_en ?? 'Service'} - {labelize(order?.status ?? 'unknown')}
                        </p>
                        <p className="mt-1">
                          {request?.locations?.address ?? 'Address not set'}, {request?.locations?.city ?? 'City'}
                        </p>
                        <p className="mt-1 whitespace-pre-wrap break-words">{request?.description ?? 'No description available.'}</p>
                        {order?.id ? (
                          <Link
                            className="mt-3 inline-flex rounded-md bg-brand-700 px-3 py-2 text-sm font-medium text-white hover:bg-brand-800"
                            href={`/orders/${order.id}`}
                          >
                            Open order trace
                          </Link>
                        ) : null}
                      </div>
                    </div>

                    <form className="w-full rounded-md bg-slate-50 p-4 xl:max-w-md" action={resolveDispute}>
                      <input name="disputeId" type="hidden" value={dispute.id} />
                      <label className="text-sm font-medium text-slate-700" htmlFor={`notes-${dispute.id}`}>
                        Resolution notes
                      </label>
                      <textarea
                        className="mt-2 min-h-24 w-full rounded-md border border-slate-300 px-3 py-2 text-sm outline-none focus:border-brand-700 focus:ring-2 focus:ring-brand-100"
                        defaultValue={dispute.resolution_notes ?? ''}
                        id={`notes-${dispute.id}`}
                        name="resolutionNotes"
                        placeholder="Record the admin decision or follow-up."
                      />
                      <div className="mt-3 grid gap-2 sm:grid-cols-3">
                        <button
                          className="rounded-md border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100"
                          formAction={reviewDispute}
                          type="submit"
                        >
                          Review
                        </button>
                        <button
                          className="inline-flex items-center justify-center gap-1 rounded-md bg-emerald-700 px-3 py-2 text-sm font-medium text-white hover:bg-emerald-800"
                          type="submit"
                        >
                          <CheckCircle2 className="h-4 w-4" />
                          Resolve
                        </button>
                        <button
                          className="rounded-md border border-rose-200 px-3 py-2 text-sm font-medium text-rose-700 hover:bg-rose-50"
                          formAction={rejectDispute}
                          type="submit"
                        >
                          Reject
                        </button>
                      </div>
                    </form>
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

function labelize(value: string) {
  return value.replaceAll('_', ' ').replace(/\b\w/g, (match) => match.toUpperCase());
}
