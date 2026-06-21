import Link from 'next/link';
import { ClipboardList, Star, UserCheck, Users } from 'lucide-react';

import { AdminShell } from '../components/admin-shell';
import { EmptyState, MetricCard } from '../components/admin-ui';
import { getAdminPatients } from '@/lib/admin-data';

export const dynamic = 'force-dynamic';

export default async function PatientsPage() {
  const patients = await getAdminPatients();
  const analytics = {
    totalPatients: patients.length,
    activeProfiles: patients.filter((patient) => patient.profiles?.is_active).length,
    patientsWithOrders: patients.filter((patient) => patient.orderCount > 0).length,
  };

  return (
    <AdminShell>
      <div className="rounded-lg border border-slate-200 bg-white p-6">
        <p className="text-sm font-medium uppercase tracking-wide text-brand-700">Patient operations</p>
        <h2 className="mt-2 text-3xl font-semibold text-slate-950">Patients</h2>
        <p className="mt-2 max-w-2xl text-slate-600">
          Review patient profiles, service activity, contact details, and account status for support and safety follow-up.
        </p>
      </div>

      <div className="mt-6 grid gap-4 md:grid-cols-3">
        <MetricCard icon={Users} label="Patients" value={analytics.totalPatients.toString()} />
        <MetricCard icon={UserCheck} label="Active profiles" value={analytics.activeProfiles.toString()} />
        <MetricCard icon={ClipboardList} label="With orders" value={analytics.patientsWithOrders.toString()} />
      </div>

      <div className="mt-6 overflow-hidden rounded-lg border border-slate-200 bg-white">
        {patients.length === 0 ? (
          <EmptyState
            title="No patients found"
            description="Patient profiles will appear after onboarding is completed."
          />
        ) : (
          <div className="divide-y divide-slate-200">
            {patients.map((patient) => (
              <article className="p-5" key={patient.id}>
                <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <h3 className="min-w-0 break-words text-lg font-semibold text-slate-950">
                        {patient.profiles?.full_name ?? 'Patient'}
                      </h3>
                      <span
                        className={`rounded-full px-2 py-1 text-xs font-medium ${
                          patient.profiles?.is_active
                            ? 'bg-emerald-50 text-emerald-800'
                            : 'bg-slate-100 text-slate-700'
                        }`}
                      >
                        {patient.profiles?.is_active ? 'Active' : 'Inactive'}
                      </span>
                      <span className="rounded-full bg-slate-100 px-2 py-1 text-xs font-medium text-slate-700">
                        {patient.profiles?.preferred_language?.toUpperCase() ?? 'EN'}
                      </span>
                    </div>
                    <p className="mt-2 break-words text-sm text-slate-600">
                      {patient.profiles?.phone ?? 'No phone'} - {patient.profiles?.email ?? 'No email'}
                    </p>
                    <p className="mt-1 break-words text-sm text-slate-500">
                      {patient.address ?? 'Address not set'}, {patient.city}
                    </p>
                    {patient.medical_notes ? (
                      <p className="mt-3 max-w-2xl text-sm text-slate-700">{patient.medical_notes}</p>
                    ) : (
                      <p className="mt-3 text-sm text-slate-500">No medical notes recorded.</p>
                    )}
                  </div>

                  <div className="grid w-full grid-cols-1 gap-3 text-sm min-[420px]:grid-cols-3 lg:w-72">
                    <Info icon={ClipboardList} label="Requests" value={patient.requestCount.toString()} />
                    <Info icon={Users} label="Orders" value={patient.orderCount.toString()} />
                    <Info icon={Star} label="Reviews" value={patient.reviewCount.toString()} />
                    <Link
                      className="rounded-md bg-brand-700 px-4 py-2 text-center text-sm font-medium text-white hover:bg-brand-800 min-[420px]:col-span-3"
                      href={`/patients/${patient.id}`}
                    >
                      Open patient
                    </Link>
                  </div>
                </div>
              </article>
            ))}
          </div>
        )}
      </div>
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
    <div className="rounded-md bg-slate-50 px-3 py-2">
      <Icon className="h-4 w-4 text-brand-700" />
      <p className="mt-2 text-xs text-slate-500">{label}</p>
      <p className="mt-1 font-semibold text-slate-950">{value}</p>
    </div>
  );
}
