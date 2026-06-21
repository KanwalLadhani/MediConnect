import Link from 'next/link';
import { notFound } from 'next/navigation';
import { ArrowLeft, FileImage, MessageSquare, Route } from 'lucide-react';

import { AdminShell } from '../../components/admin-shell';
import { sanitizeAuditMetadata } from '@/lib/admin-audit-metadata';
import {
  getAdminOrder,
  getAdminOrderEventsForOrder,
  getAdminMedicalRecordsForOrder,
  getAdminOrderMessages,
} from '@/lib/admin-data';

export const dynamic = 'force-dynamic';

export default async function OrderDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const [order, events, messages, medicalRecords] = await Promise.all([
    getAdminOrder(id),
    getAdminOrderEventsForOrder(id),
    getAdminOrderMessages(id),
    getAdminMedicalRecordsForOrder(id),
  ]);

  if (!order) {
    notFound();
  }

  const request = order.service_requests;
  const price = order.final_price_pkr ?? order.quoted_price_pkr;
  const latestLocation = latestWorkerLocation(order.worker_locations);

  return (
    <AdminShell>
      <Link className="inline-flex items-center gap-2 text-sm font-medium text-slate-600 hover:text-slate-950" href="/orders">
        <ArrowLeft className="h-4 w-4" />
        Orders
      </Link>

      <div className="mt-4 rounded-lg border border-slate-200 bg-white p-6">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div className="min-w-0">
            <p className="text-sm font-medium uppercase tracking-wide text-brand-700">Order trace</p>
            <h2 className="mt-2 break-words text-3xl font-semibold text-slate-950">
              {request?.service_categories?.name_en ?? 'Service'}
            </h2>
            <p className="mt-2 break-words text-slate-600">
              Patient: {order.patients?.profiles?.full_name ?? 'Patient'} - Worker:{' '}
              {order.health_workers?.profiles?.full_name ?? 'Worker'}
            </p>
          </div>
          <span className="w-fit rounded-full bg-slate-100 px-3 py-1 text-sm font-medium text-slate-700">
            {labelize(order.status)}
          </span>
        </div>

        <div className="mt-6 grid gap-4 md:grid-cols-3">
          <Info label="Price" value={`PKR ${price.toLocaleString()}`} />
          <Info
            label="Commission"
            value={`PKR ${(order.platform_commission_pkr ?? 0).toLocaleString()}`}
          />
          <Info label="Created" value={new Date(order.created_at).toLocaleString()} />
          <Info label="Patient phone" value={order.patients?.profiles?.phone ?? 'Not provided'} />
          <Info label="Worker phone" value={order.health_workers?.profiles?.phone ?? 'Not provided'} />
          <Info label="Location" value={`${request?.locations?.address ?? 'Address'}, ${request?.locations?.city ?? 'City'}`} />
        </div>

        <p className="mt-5 max-w-3xl whitespace-pre-wrap break-words text-sm text-slate-700">
          {request?.description ?? 'No description provided.'}
        </p>

        {latestLocation ? (
          <div className="mt-5 flex gap-3 rounded-md bg-brand-50 p-4 text-sm text-brand-900">
            <Route className="h-5 w-5 shrink-0" aria-hidden="true" />
            <p className="min-w-0 break-words">
              Latest worker location: {latestLocation.latitude.toFixed(5)},{' '}
              {latestLocation.longitude.toFixed(5)} at {new Date(latestLocation.createdAt).toLocaleString()}
            </p>
          </div>
        ) : null}
      </div>

      <div className="mt-6 grid gap-6 xl:grid-cols-2">
        <section className="rounded-lg border border-slate-200 bg-white p-6">
          <h3 className="text-lg font-semibold text-slate-950">Request evidence</h3>
          <div className="mt-4 rounded-md bg-slate-50 p-4 text-sm text-slate-700">
            {request?.image_path ? (
              <>
                <p className="flex items-center gap-2 break-all">
                  <FileImage className="h-4 w-4 shrink-0 text-brand-700" aria-hidden="true" />
                  {request.image_path}
                </p>
                {request.imageSignedUrl ? (
                  <a
                    className="mt-3 inline-flex rounded-md border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100"
                    href={request.imageSignedUrl}
                    rel="noreferrer"
                    target="_blank"
                  >
                    Open request image
                  </a>
                ) : (
                  <p className="mt-2 text-slate-500">Image link unavailable or expired.</p>
                )}
              </>
            ) : (
              <p>No request image attached.</p>
            )}
          </div>
        </section>

        <section className="rounded-lg border border-slate-200 bg-white p-6">
          <h3 className="text-lg font-semibold text-slate-950">Completion notes</h3>
          <div className="mt-4 space-y-4">
            {medicalRecords.length === 0 ? (
              <p className="rounded-md bg-slate-50 p-4 text-sm text-slate-600">
                No completion notes recorded for this order.
              </p>
            ) : (
              medicalRecords.map((record) => (
                <article className="rounded-md bg-slate-50 p-4 text-sm text-slate-700" key={record.id}>
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <p className="min-w-0 break-words font-medium text-slate-950">
                      {record.health_workers?.profiles?.full_name ?? 'Worker'}
                    </p>
                    <p className="text-xs text-slate-500">{new Date(record.created_at).toLocaleString()}</p>
                  </div>
                  <p className="mt-2 whitespace-pre-wrap break-words">{record.notes || 'No written notes.'}</p>
                  {record.file_path ? (
                    <div className="mt-3">
                      <p className="flex items-center gap-2 break-all text-slate-600">
                        <FileImage className="h-4 w-4 shrink-0" aria-hidden="true" />
                        {record.file_path}
                      </p>
                      {record.fileSignedUrl ? (
                        <a
                          className="mt-2 inline-flex rounded-md border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100"
                          href={record.fileSignedUrl}
                          rel="noreferrer"
                          target="_blank"
                        >
                          Open record file
                        </a>
                      ) : null}
                    </div>
                  ) : null}
                </article>
              ))
            )}
          </div>
        </section>
      </div>

      <div className="mt-6 grid gap-6 xl:grid-cols-2">
        <section className="rounded-lg border border-slate-200 bg-white p-6">
          <h3 className="text-lg font-semibold text-slate-950">Event timeline</h3>
          <div className="mt-4 space-y-4">
            {events.length === 0 ? (
              <p className="text-sm text-slate-600">No events recorded.</p>
            ) : (
              events.map((event) => (
                <article className="rounded-md bg-slate-50 p-4" key={event.id}>
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <p className="min-w-0 break-words font-medium text-slate-950">{labelize(event.event_type)}</p>
                    <p className="text-xs text-slate-500">{new Date(event.created_at).toLocaleString()}</p>
                  </div>
                  <p className="mt-1 text-sm text-slate-600">
                    Actor: {event.profiles?.full_name ?? 'System'} - {event.profiles?.role ?? 'system'}
                  </p>
                  <SafeMetadataChips items={sanitizeAuditMetadata(event.metadata)} />
                </article>
              ))
            )}
          </div>
        </section>

        <section className="rounded-lg border border-slate-200 bg-white p-6">
          <h3 className="text-lg font-semibold text-slate-950">Chat trace</h3>
          <div className="mt-4 space-y-4">
            {messages.length === 0 ? (
              <p className="text-sm text-slate-600">No chat messages recorded.</p>
            ) : (
              messages.map((message) => (
                <article className="rounded-md bg-slate-50 p-4" key={message.id}>
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <p className="flex items-center gap-2 font-medium text-slate-950">
                      <MessageSquare className="h-4 w-4 shrink-0 text-brand-700" aria-hidden="true" />
                      <span className="min-w-0 break-words">
                        {message.sender?.full_name ?? 'User'} - {message.sender?.role ?? 'unknown'}
                      </span>
                    </p>
                    <p className="text-xs text-slate-500">{new Date(message.created_at).toLocaleString()}</p>
                  </div>
                  {message.body ? <p className="mt-3 whitespace-pre-wrap break-words text-sm text-slate-700">{message.body}</p> : null}
                  {message.file_path ? (
                    <div className="mt-3 text-sm text-slate-600">
                      <p className="flex items-center gap-2 break-all">
                        <FileImage className="h-4 w-4 shrink-0" aria-hidden="true" />
                        {message.file_path}
                      </p>
                      {message.fileSignedUrl ? (
                        <a
                          className="mt-2 inline-flex rounded-md border border-slate-200 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-white"
                          href={message.fileSignedUrl}
                          rel="noreferrer"
                          target="_blank"
                        >
                          Open image
                        </a>
                      ) : null}
                    </div>
                  ) : null}
                </article>
              ))
            )}
          </div>
        </section>
      </div>
    </AdminShell>
  );
}

function SafeMetadataChips({
  items,
}: {
  items: {
    label: string;
    value: string;
  }[];
}) {
  if (items.length === 0) {
    return (
      <p className="mt-3 text-xs text-slate-500">
        No safe metadata to display.
      </p>
    );
  }

  return (
    <dl className="mt-3 flex flex-wrap gap-2">
      {items.map((item) => (
        <div
          className="max-w-full rounded-full border border-slate-200 bg-white px-3 py-1 text-xs"
          key={`${item.label}:${item.value}`}
        >
          <dt className="inline text-slate-500">{item.label}: </dt>
          <dd className="inline break-words font-medium text-slate-900">{item.value}</dd>
        </div>
      ))}
    </dl>
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

function latestWorkerLocation(
  locations: {
    latitude: number | string;
    longitude: number | string;
    created_at: string;
  }[] = [],
) {
  const [latest] = [...locations].sort(
    (a, b) =>
      new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
  );

  if (!latest) {
    return null;
  }

  return {
    latitude: Number(latest.latitude),
    longitude: Number(latest.longitude),
    createdAt: latest.created_at,
  };
}
