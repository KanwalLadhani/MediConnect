import { revalidatePath } from 'next/cache';
import { HeartPulse, ToggleLeft, UserCheck } from 'lucide-react';

import { AdminShell } from '../components/admin-shell';
import { EmptyState, InfoTile, MetricCard } from '../components/admin-ui';
import { getAdminServiceCategories, updateServiceCategoryStatus } from '@/lib/admin-data';
import { parseServiceStatusForm } from '@/lib/admin-service-status';

export const dynamic = 'force-dynamic';

async function setServiceStatus(formData: FormData) {
  'use server';

  await updateServiceCategoryStatus(parseServiceStatusForm(formData));
  revalidatePath('/services');
}

export default async function ServicesPage() {
  const services = await getAdminServiceCategories();
  const analytics = {
    total: services.length,
    active: services.filter((service) => service.is_active).length,
    covered: services.filter((service) => service.workerOfferingCount > 0).length,
  };

  return (
    <AdminShell>
      <div className="rounded-lg border border-slate-200 bg-white p-6">
        <p className="text-sm font-medium uppercase tracking-wide text-brand-700">Service catalogue</p>
        <h2 className="mt-2 text-3xl font-semibold text-slate-950">Services</h2>
        <p className="mt-2 max-w-2xl text-slate-600">
          Monitor the patient-facing service catalogue, Urdu labels, worker coverage, and request demand.
        </p>
      </div>

      <div className="mt-6 grid gap-4 md:grid-cols-3">
        <MetricCard icon={HeartPulse} label="Service categories" value={analytics.total.toString()} />
        <MetricCard icon={ToggleLeft} label="Active services" value={analytics.active.toString()} />
        <MetricCard icon={UserCheck} label="With worker coverage" value={analytics.covered.toString()} />
      </div>

      <div className="mt-6 overflow-hidden rounded-lg border border-slate-200 bg-white">
        {services.length === 0 ? (
          <EmptyState
            title="No services found"
            description="Seed service categories before opening patient requests."
          />
        ) : (
          <div className="divide-y divide-slate-200">
            {services.map((service) => (
              <article className="p-5" key={service.id}>
                <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <h3 className="min-w-0 break-words text-lg font-semibold text-slate-950">{service.name_en}</h3>
                      <span
                        className={`rounded-full px-2 py-1 text-xs font-medium ${
                          service.is_active ? 'bg-emerald-50 text-emerald-800' : 'bg-slate-100 text-slate-700'
                        }`}
                      >
                        {service.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </div>
                    <p className="mt-1 break-words text-sm text-slate-600" dir="auto" lang="ur">
                      {service.name_ur}
                    </p>
                    <p className="mt-3 max-w-2xl text-sm text-slate-700">
                      {service.description_en ?? 'No English description.'}
                    </p>
                    <p className="mt-1 max-w-2xl break-words text-sm text-slate-500" dir="auto" lang="ur">
                      {service.description_ur ?? 'No Urdu description.'}
                    </p>
                  </div>

                  <div className="grid w-full grid-cols-1 gap-3 text-sm min-[420px]:grid-cols-2 lg:w-72">
                    <InfoTile label="Requests" value={service.requestCount.toString()} />
                    <InfoTile label="Workers" value={service.workerOfferingCount.toString()} />
                    <form action={setServiceStatus} className="min-[420px]:col-span-2">
                      <input name="categoryId" type="hidden" value={service.id} />
                      <input name="isActive" type="hidden" value={(!service.is_active).toString()} />
                      <button
                        className={`w-full rounded-md px-4 py-2 text-sm font-medium ${
                          service.is_active
                            ? 'border border-amber-200 text-amber-800 hover:bg-amber-50'
                            : 'bg-emerald-700 text-white hover:bg-emerald-800'
                        }`}
                        type="submit"
                      >
                        {service.is_active ? 'Deactivate service' : 'Activate service'}
                      </button>
                    </form>
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
