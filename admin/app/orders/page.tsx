import Link from 'next/link';
import { Activity, Banknote, Users } from 'lucide-react';

import { AdminShell } from '../components/admin-shell';
import { EmptyState, InfoTile, MetricCard } from '../components/admin-ui';
import { getAdminOrderAnalytics, getAdminOrders } from '@/lib/admin-data';

export const dynamic = 'force-dynamic';

const statuses = [
  'all',
  'accepted',
  'worker_on_way',
  'started',
  'completed',
  'cancelled',
  'disputed',
];

export default async function OrdersPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  const { status } = await searchParams;
  const activeStatus =
    status && statuses.includes(status) && status !== 'all' ? status : undefined;
  const [orders, analytics] = await Promise.all([
    getAdminOrders(activeStatus),
    getAdminOrderAnalytics(),
  ]);

  return (
    <AdminShell>
      <div className="rounded-lg border border-slate-200 bg-white p-6">
        <p className="text-sm font-medium uppercase tracking-wide text-brand-700">Order monitoring</p>
        <h2 className="mt-2 text-3xl font-semibold text-slate-950">Orders</h2>
        <p className="mt-2 max-w-2xl text-slate-600">
          Monitor active services, completed orders, platform commission, and patient-worker activity.
        </p>
      </div>

      <div className="mt-6 grid gap-4 md:grid-cols-3">
        <MetricCard icon={Activity} label="Completed orders" value={analytics.completedOrders.toString()} />
        <MetricCard icon={Banknote} label="Gross completed" value={`PKR ${analytics.completedGrossPkr.toLocaleString()}`} />
        <MetricCard icon={Users} label="Available workers" value={analytics.availableWorkers.toString()} />
      </div>

      <div className="mt-6 flex flex-wrap gap-2" aria-label="Order status filters">
        {statuses.map((item) => (
          <Link
            className={`rounded-md px-3 py-2 text-sm font-medium ${
              (activeStatus ?? 'all') === item
                ? 'bg-brand-700 text-white'
                : 'border border-slate-200 bg-white text-slate-700 hover:bg-slate-100'
            }`}
            href={item === 'all' ? '/orders' : `/orders?status=${item}`}
            key={item}
          >
            {labelize(item)}
          </Link>
        ))}
      </div>

      <div className="mt-6 overflow-hidden rounded-lg border border-slate-200 bg-white">
        {orders.length === 0 ? (
          <EmptyState
            title="No orders found"
            description="Orders will appear here after workers accept requests."
          />
        ) : (
          <div className="divide-y divide-slate-200">
            {orders.map((order) => {
              const request = order.service_requests;
              const price = order.final_price_pkr ?? order.quoted_price_pkr;
              const latestLocation = latestWorkerLocation(order.worker_locations);
              return (
                <article className="p-5" key={order.id}>
                  <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                    <div className="min-w-0">
                      <div className="flex flex-wrap items-center gap-2">
                        <h3 className="min-w-0 break-words text-lg font-semibold text-slate-950">
                          {request?.service_categories?.name_en ?? 'Service'}
                        </h3>
                        <span className="rounded-full bg-slate-100 px-2 py-1 text-xs font-medium text-slate-700">
                          {labelize(order.status)}
                        </span>
                      </div>
                      <p className="mt-2 break-words text-sm text-slate-600">
                        Patient: {order.patients?.profiles?.full_name ?? 'Patient'} - Worker:{' '}
                        {order.health_workers?.profiles?.full_name ?? 'Worker'}
                      </p>
                      <p className="mt-1 break-words text-sm text-slate-500">
                        {request?.locations?.address ?? 'Address not set'}, {request?.locations?.city ?? 'City'}
                      </p>
                      <p className="mt-3 max-w-2xl text-sm text-slate-700">
                        {request?.description ?? 'No description provided.'}
                      </p>
                      {latestLocation ? (
                        <p className="mt-3 rounded-md bg-slate-50 px-3 py-2 text-sm text-slate-700">
                          Latest worker location: {latestLocation.latitude.toFixed(5)},{' '}
                          {latestLocation.longitude.toFixed(5)} at {formatDateTime(latestLocation.createdAt)}
                        </p>
                      ) : null}
                    </div>
                    <div className="grid w-full grid-cols-1 gap-3 text-sm min-[420px]:grid-cols-2 lg:w-72">
                      <InfoTile label="Price" value={`PKR ${price.toLocaleString()}`} />
                      <InfoTile
                        label="Commission"
                        value={`PKR ${(order.platform_commission_pkr ?? 0).toLocaleString()}`}
                      />
                      <Link
                        className="rounded-md bg-brand-700 px-4 py-2 text-center text-sm font-medium text-white hover:bg-brand-800 min-[420px]:col-span-2"
                        href={`/orders/${order.id}`}
                      >
                        Open trace
                      </Link>
                    </div>
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

function formatDateTime(value: string) {
  return new Date(value).toLocaleString();
}
