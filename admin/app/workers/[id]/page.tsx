import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { revalidatePath } from 'next/cache';
import { ArrowLeft, CheckCircle2, ExternalLink, FileText, ShieldAlert, XCircle } from 'lucide-react';

import { AdminShell } from '../../components/admin-shell';
import { getAdminOrdersForWorker, getWorker, updateWorkerVerification } from '@/lib/admin-data';
import { parseWorkerVerificationForm } from '@/lib/admin-worker-verification';

export const dynamic = 'force-dynamic';

async function approveWorker(formData: FormData) {
  'use server';

  const decision = parseWorkerVerificationForm(formData, 'approved');
  await updateWorkerVerification(decision);
  revalidatePath('/workers');
  revalidatePath(`/workers/${decision.workerId}`);
  redirect(`/workers/${decision.workerId}`);
}

async function rejectWorker(formData: FormData) {
  'use server';

  const decision = parseWorkerVerificationForm(formData, 'rejected');
  await updateWorkerVerification(decision);
  revalidatePath('/workers');
  revalidatePath(`/workers/${decision.workerId}`);
  redirect(`/workers/${decision.workerId}`);
}

export default async function WorkerDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const [worker, orders] = await Promise.all([
    getWorker(id),
    getAdminOrdersForWorker(id),
  ]);

  if (!worker) {
    notFound();
  }

  return (
    <AdminShell>
      <Link className="inline-flex items-center gap-2 text-sm font-medium text-slate-600 hover:text-slate-950" href="/workers">
        <ArrowLeft className="h-4 w-4" />
        Workers
      </Link>

      <div className="mt-4 rounded-lg border border-slate-200 bg-white p-6">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div className="min-w-0">
            <p className="text-sm font-medium uppercase tracking-wide text-brand-700">Verification profile</p>
            <h2 className="mt-2 break-words text-3xl font-semibold text-slate-950">
              {worker.profiles?.full_name ?? 'Unnamed worker'}
            </h2>
            <p className="mt-2 break-words text-slate-600">
              {labelize(worker.worker_type)} - {worker.qualification} - {worker.city}
            </p>
          </div>
          <span className="w-fit rounded-full bg-slate-100 px-3 py-1 text-sm font-medium text-slate-700">
            {labelize(worker.verification_status)}
          </span>
        </div>

        {worker.rejection_reason ? (
          <div className="mt-5 flex gap-3 rounded-md bg-rose-50 p-4 text-rose-900">
            <ShieldAlert className="h-5 w-5 shrink-0" />
            <p className="text-sm">{worker.rejection_reason}</p>
          </div>
        ) : null}

        <div className="mt-6 grid gap-4 md:grid-cols-3">
          <Info label="Phone" value={worker.profiles?.phone ?? 'Not provided'} />
          <Info label="Email" value={worker.profiles?.email ?? 'Not provided'} />
          <Info label="Service area" value={worker.service_area ?? 'Not provided'} />
          <Info label="Experience" value={`${worker.experience_years ?? 0} years`} />
          <Info label="Rating" value={`${worker.average_rating} from ${worker.total_reviews} reviews`} />
          <Info label="Completed orders" value={worker.total_completed_orders.toString()} />
        </div>
      </div>

      <div className="mt-6 grid gap-6 xl:grid-cols-[1.4fr_0.8fr]">
        <section className="rounded-lg border border-slate-200 bg-white p-6">
          <h3 className="text-lg font-semibold text-slate-950">Documents</h3>
          <div className="mt-4 divide-y divide-slate-200">
            {worker.worker_documents.length === 0 ? (
              <p className="py-5 text-sm text-slate-600">No documents uploaded yet.</p>
            ) : (
              worker.worker_documents.map((document) => (
                <div className="flex flex-col gap-3 py-4 md:flex-row md:items-center md:justify-between" key={document.id}>
                  <div className="flex items-start gap-3">
                    <FileText className="mt-0.5 h-5 w-5 shrink-0 text-brand-700" aria-hidden="true" />
                    <div className="min-w-0">
                      <p className="break-words font-medium text-slate-950">{labelize(document.document_type)}</p>
                      <p className="mt-1 break-all text-sm text-slate-500">{document.file_path}</p>
                    </div>
                  </div>
                  <div className="flex flex-wrap items-center gap-2">
                    {document.signedUrl ? (
                      <a
                        className="inline-flex items-center gap-1 rounded-md border border-slate-200 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                        href={document.signedUrl}
                        rel="noreferrer"
                        target="_blank"
                      >
                        <ExternalLink className="h-4 w-4" />
                        Open document
                      </a>
                    ) : null}
                    <span className="w-fit rounded-full bg-slate-100 px-2 py-1 text-xs font-medium text-slate-700">
                      {labelize(document.status)}
                    </span>
                  </div>
                </div>
              ))
            )}
          </div>
        </section>

        <section className="rounded-lg border border-slate-200 bg-white p-6">
          <h3 className="text-lg font-semibold text-slate-950">Decision</h3>
          <p className="mt-1 text-sm text-slate-600">
            Approved workers can appear in patient request matching once they mark themselves available.
          </p>

          <form action={approveWorker} className="mt-5">
            <input name="workerId" type="hidden" value={worker.id} />
            <button
              className="inline-flex w-full items-center justify-center gap-2 rounded-md bg-emerald-700 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-800"
              type="submit"
            >
              <CheckCircle2 className="h-4 w-4" />
              Approve worker
            </button>
          </form>

          <form action={rejectWorker} className="mt-4">
            <input name="workerId" type="hidden" value={worker.id} />
            <label className="text-sm font-medium text-slate-700" htmlFor="rejectionReason">
              Rejection reason
            </label>
            <textarea
              className="mt-2 min-h-28 w-full rounded-md border border-slate-300 px-3 py-2 text-sm outline-none focus:border-brand-700 focus:ring-2 focus:ring-brand-100"
              id="rejectionReason"
              name="rejectionReason"
              placeholder="Explain what needs to be corrected before approval."
            />
            <button
              className="mt-3 inline-flex w-full items-center justify-center gap-2 rounded-md border border-rose-200 px-4 py-2 text-sm font-medium text-rose-700 hover:bg-rose-50"
              type="submit"
            >
              <XCircle className="h-4 w-4" />
              Reject or request changes
            </button>
          </form>
        </section>
      </div>

      <section className="mt-6 rounded-lg border border-slate-200 bg-white p-6">
        <h3 className="text-lg font-semibold text-slate-950">Offered services</h3>
        <div className="mt-4 grid gap-3 md:grid-cols-2 xl:grid-cols-3">
          {worker.worker_services.length === 0 ? (
            <p className="text-sm text-slate-600">No services configured.</p>
          ) : (
            worker.worker_services.map((service) => (
              <div className="min-w-0 rounded-md bg-slate-50 p-4" key={service.id}>
                <p className="break-words font-medium text-slate-950">{service.service_categories?.name_en ?? 'Service'}</p>
                <p className="mt-1 text-sm text-slate-600">PKR {service.base_price_pkr.toLocaleString()}</p>
              </div>
            ))
          )}
        </div>
      </section>

      <section className="mt-6 rounded-lg border border-slate-200 bg-white p-6">
        <h3 className="text-lg font-semibold text-slate-950">Order history</h3>
        <div className="mt-4 divide-y divide-slate-200">
          {orders.length === 0 ? (
            <p className="py-5 text-sm text-slate-600">No orders for this worker yet.</p>
          ) : (
            orders.map((order) => {
              const request = order.service_requests;
              const price = order.final_price_pkr ?? order.quoted_price_pkr;
              return (
                <article className="flex flex-col gap-3 py-4 lg:flex-row lg:items-center lg:justify-between" key={order.id}>
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="min-w-0 break-words font-semibold text-slate-950">
                        {request?.service_categories?.name_en ?? 'Service'}
                      </p>
                      <span className="rounded-full bg-slate-100 px-2 py-1 text-xs font-medium text-slate-700">
                        {labelize(order.status)}
                      </span>
                    </div>
                    <p className="mt-1 break-words text-sm text-slate-600">
                      Patient: {order.patients?.profiles?.full_name ?? 'Patient'} - PKR {price.toLocaleString()}
                    </p>
                    <p className="mt-1 text-sm text-slate-500">{new Date(order.created_at).toLocaleString()}</p>
                  </div>
                  <Link
                    className="w-fit rounded-md bg-brand-700 px-4 py-2 text-sm font-medium text-white hover:bg-brand-800"
                    href={`/orders/${order.id}`}
                  >
                    Open trace
                  </Link>
                </article>
              );
            })
          )}
        </div>
      </section>
    </AdminShell>
  );
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-md bg-slate-50 p-4">
      <p className="text-xs font-medium uppercase tracking-wide text-slate-500">{label}</p>
      <p className="mt-2 break-words text-sm font-semibold text-slate-950">{value}</p>
    </div>
  );
}

function labelize(value: string) {
  return value.replaceAll('_', ' ').replace(/\b\w/g, (match) => match.toUpperCase());
}
