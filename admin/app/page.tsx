import { Activity, BadgeCheck, ClipboardList, CreditCard, FileClock, FileWarning, HeartPulse, Settings, Star, Users } from 'lucide-react';
import Link from 'next/link';

import { AdminShell } from './components/admin-shell';
import { MetricCard, PageHeader } from './components/admin-ui';
import {
  getAdminOrderAnalytics,
  getAdminStats,
  getAdminWalletAnalytics,
} from '@/lib/admin-data';
import { isSupabaseConfigured } from '@/lib/supabase';

export const dynamic = 'force-dynamic';

export default async function AdminHome() {
  const [counts, orderAnalytics, walletAnalytics] = await Promise.all([
    getAdminStats(),
    getAdminOrderAnalytics(),
    getAdminWalletAnalytics(),
  ]);
  const stats = [
    { label: 'Pending verifications', value: counts.pendingVerifications, icon: BadgeCheck },
    { label: 'Active orders', value: counts.activeOrders, icon: Activity },
    { label: 'Wallet top-ups', value: counts.walletTopUps, icon: CreditCard },
    { label: 'Open disputes', value: counts.openDisputes, icon: FileWarning },
  ];
  const financeStats = [
    {
      label: 'Completed gross',
      value: `PKR ${orderAnalytics.completedGrossPkr.toLocaleString()}`,
      detail: `${orderAnalytics.completedOrders.toLocaleString()} completed order(s)`,
      icon: ClipboardList,
    },
    {
      label: 'Platform commission',
      value: `PKR ${orderAnalytics.totalCommissionPkr.toLocaleString()}`,
      detail: 'Recorded from completed services',
      icon: Activity,
    },
    {
      label: 'Worker wallet balance',
      value: `PKR ${walletAnalytics.totalWalletBalancePkr.toLocaleString()}`,
      detail: `${walletAnalytics.negativeWallets} negative, ${walletAnalytics.frozenWallets} frozen`,
      icon: CreditCard,
    },
    {
      label: 'Available workers',
      value: orderAnalytics.availableWorkers.toLocaleString(),
      detail: 'Approved workers currently available',
      icon: Users,
    },
  ];
  const shortcuts = [
    { href: '/workers', label: 'Workers', description: 'Verify profiles and documents.', icon: BadgeCheck },
    { href: '/patients', label: 'Patients', description: 'Review patient profiles and activity.', icon: Users },
    { href: '/services', label: 'Services', description: 'Monitor service catalogue coverage.', icon: HeartPulse },
    { href: '/orders', label: 'Orders', description: 'Track active and completed services.', icon: ClipboardList },
    { href: '/wallets', label: 'Wallets', description: 'Approve manual top-up requests.', icon: CreditCard },
    { href: '/reviews', label: 'Reviews', description: 'Inspect patient service feedback.', icon: Star },
    { href: '/disputes', label: 'Disputes', description: 'Handle reported service issues.', icon: FileWarning },
    { href: '/audit-logs', label: 'Audit Logs', description: 'Trace order events and actors.', icon: FileClock },
    { href: '/settings', label: 'Settings', description: 'Check environment and launch readiness.', icon: Settings },
  ];

  return (
    <AdminShell>
      <PageHeader eyebrow="Pakistan MVP" title="Admin dashboard">
        <p>
          Review worker documents, monitor orders, approve wallet top-ups, and track platform commission.
        </p>
        {!isSupabaseConfigured ? (
          <p className="mt-4 rounded-md bg-amber-50 px-3 py-2 text-sm text-amber-800">
            Add Supabase environment variables to load live operations data.
          </p>
        ) : null}
      </PageHeader>

      <div className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {stats.map((stat) => (
          <MetricCard
            icon={stat.icon}
            key={stat.label}
            label={stat.label}
            value={stat.value.toString()}
          />
        ))}
      </div>

      <div className="mt-6 grid gap-4 lg:grid-cols-2 xl:grid-cols-4">
        {financeStats.map((stat) => (
          <MetricCard
            detail={stat.detail}
            icon={stat.icon}
            key={stat.label}
            label={stat.label}
            value={stat.value}
          />
        ))}
      </div>

      <div className="mt-6 rounded-lg border border-slate-200 bg-white p-5">
        <h3 className="text-lg font-semibold text-slate-950">Verification queue</h3>
        <p className="mt-1 text-sm text-slate-600">
          Review pending worker profiles, documents, service pricing, and approval status.
        </p>
        <Link
          className="mt-4 inline-flex rounded-md bg-brand-700 px-4 py-2 text-sm font-medium text-white hover:bg-brand-800"
          href="/workers"
        >
          Open workers
        </Link>
      </div>

      <div className="mt-6 rounded-lg border border-slate-200 bg-white p-5">
        <h3 className="text-lg font-semibold text-slate-950">Operations shortcuts</h3>
        <div className="mt-4 grid gap-3 md:grid-cols-2 xl:grid-cols-3">
          {shortcuts.map((item) => (
            <Link
              className="min-w-0 rounded-md border border-slate-200 p-4 text-sm hover:bg-slate-50"
              href={item.href}
              key={item.href}
            >
              <div className="flex items-center gap-2 font-semibold text-slate-950">
                <item.icon className="h-4 w-4 shrink-0 text-brand-700" />
                <span className="min-w-0 break-words">{item.label}</span>
              </div>
              <p className="mt-2 text-slate-600">{item.description}</p>
            </Link>
          ))}
        </div>
      </div>
    </AdminShell>
  );
}
