import Link from 'next/link';
import { notFound } from 'next/navigation';
import { ArrowLeft, ClipboardList, FileImage, FileText, Mail, Phone, UserRound } from 'lucide-react';

import { AdminShell } from '../../components/admin-shell';
import { getAdminMedicalRecordsForPatient, getAdminOrdersForPatient, getAdminPatient } from '@/lib/admin-data';

export const dynamic = 'force-dynamic';

export default async function PatientDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const [patient, orders, medicalRecords] = await Promise.all([
    getAdminPatient(id),
    getAdminOrdersForPatient(id),
    getAdminMedicalRecordsForPatient(id),
  ]);

  if (!patient) {
    notFound();
  }

  return (
    <AdminShell>
      <Link className="inline-flex items-center gap-2 text-sm font-medium text-slate-600 hover:text-slate-950" href="/patients">
        <ArrowLeft className="h-4 w-4" />
        Patients
      </Link>

      <div className="mt-4 rounded-lg border border-slate-200 bg-white p-6">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div className="min-w-0">
            <p className="text-sm font-medium uppercase tracking-wide text-brand-700">Patient profile</p>
            <h2 className="mt-2 break-words text-3xl font-semibold text-slate-950">
              {patient.profiles?.full_name ?? 'Patient'}
            </h2>
            <p className="mt-2 break-words text-slate-600">
              {patient.address ?? 'Address not set'}, {patient.city}
            </p>
          </div>
          <span
            className={`w-fit rounded-full px-3 py-1 text-sm font-medium ${
              patient.profiles?.is_active ? 'bg-emerald-50 text-emerald-800' : 'bg-slate-100 text-slate-700'
            }`}
          >
            {patient.profiles?.is_active ? 'Active' : 'Inactive'}
          </span>
        </div>

        <div className="mt-6 grid gap-4 md:grid-cols-3">
          <Info icon={Phone} label="Phone" value={patient.profiles?.phone ?? 'Not provided'} />
          <Info icon={Mail} label="Email" value={patient.profiles?.email ?? 'Not provided'} />
          <Info icon={UserRound} label="Language" value={patient.profiles?.preferred_language?.toUpperCase() ?? 'EN'} />
          <Info icon={ClipboardList} label="Requests" value={patient.requestCount.toString()} />
          <Info icon={ClipboardList} label="Orders" value={patient.orderCount.toString()} />
          <Info icon={ClipboardList} label="Reviews" value={patient.reviewCount.toString()} />
        </div>

        <div className="mt-6 rounded-md bg-slate-50 p-4">
          <p className="text-xs font-medium uppercase tracking-wide text-slate-500">Medical notes</p>
          <p className="mt-2 whitespace-pre-wrap break-words text-sm text-slate-700">
            {patient.medical_notes ?? 'No medical notes recorded.'}
          </p>
        </div>
      </div>

      <section className="mt-6 rounded-lg border border-slate-200 bg-white p-6">
        <h3 className="text-lg font-semibold text-slate-950">Medical records</h3>
        <p className="mt-1 text-sm text-slate-600">
          Worker notes saved when services are completed.
        </p>
        <div className="mt-4 divide-y divide-slate-200">
          {medicalRecords.length === 0 ? (
            <p className="py-5 text-sm text-slate-600">No medical records for this patient yet.</p>
          ) : (
            medicalRecords.map((record) => (
              <article className="py-4" key={record.id}>
                <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
                  <div className="min-w-0">
                    <div className="flex items-center gap-2 font-semibold text-slate-950">
                      <FileText className="h-4 w-4 shrink-0 text-brand-700" aria-hidden="true" />
                      <span className="min-w-0 break-words">{record.health_workers?.profiles?.full_name ?? 'Health worker'}</span>
                    </div>
                    <p className="mt-1 text-sm text-slate-500">
                      {new Date(record.created_at).toLocaleString()} - {labelize(record.health_workers?.worker_type ?? 'worker')}
                    </p>
                    <p className="mt-3 max-w-3xl whitespace-pre-wrap text-sm text-slate-700">
                      {record.notes ?? 'No note text recorded.'}
                    </p>
                    {record.file_path ? (
                      <div className="mt-3 text-sm text-slate-600">
                        <p className="flex items-center gap-2 break-all">
                          <FileImage className="h-4 w-4 shrink-0" />
                          {record.file_path}
                        </p>
                        {record.fileSignedUrl ? (
                          <a
                            className="mt-2 inline-flex rounded-md border border-slate-200 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                            href={record.fileSignedUrl}
                            rel="noreferrer"
                            target="_blank"
                          >
                            Open record file
                          </a>
                        ) : null}
                      </div>
                    ) : null}
                  </div>
                  {record.order_id ? (
                    <Link
                      className="w-fit rounded-md border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                      href={`/orders/${record.order_id}`}
                    >
                      Open order
                    </Link>
                  ) : null}
                </div>
              </article>
            ))
          )}
        </div>
      </section>

      <section className="mt-6 rounded-lg border border-slate-200 bg-white p-6">
        <h3 className="text-lg font-semibold text-slate-950">Orders</h3>
        <div className="mt-4 divide-y divide-slate-200">
          {orders.length === 0 ? (
            <p className="py-5 text-sm text-slate-600">No orders for this patient yet.</p>
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
                      Worker: {order.health_workers?.profiles?.full_name ?? 'Worker'} - PKR {price.toLocaleString()}
                    </p>
                    <p className="mt-1 text-sm text-slate-500">
                      {new Date(order.created_at).toLocaleString()}
                    </p>
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

function Info({
  icon: Icon,
  label,
  value,
}: {
  icon: React.ComponentType<{ className?: string }>;
  label: string;
  value: string;
}) {
  return (
    <div className="rounded-md bg-slate-50 p-4">
      <Icon className="h-4 w-4 shrink-0 text-brand-700" aria-hidden="true" />
      <p className="mt-2 text-xs font-medium uppercase tracking-wide text-slate-500">{label}</p>
      <p className="mt-2 break-words text-sm font-semibold text-slate-950">{value}</p>
    </div>
  );
}

function labelize(value: string) {
  return value.replaceAll('_', ' ').replace(/\b\w/g, (match) => match.toUpperCase());
}
