import Link from 'next/link';
import {
  Activity,
  BadgeCheck,
  ClipboardList,
  CreditCard,
  FileClock,
  FileWarning,
  HeartPulse,
  Settings,
  Star,
  Users,
} from 'lucide-react';
import { logoutAdmin } from '../admin-actions';
import { getAdminAuthMode } from '@/lib/admin-access';

const navItems = [
  { href: '/', label: 'Dashboard', icon: Activity },
  { href: '/workers', label: 'Workers', icon: BadgeCheck },
  { href: '/patients', label: 'Patients', icon: Users },
  { href: '/services', label: 'Services', icon: HeartPulse },
  { href: '/orders', label: 'Orders', icon: ClipboardList },
  { href: '/wallets', label: 'Wallets', icon: CreditCard },
  { href: '/reviews', label: 'Reviews', icon: Star },
  { href: '/disputes', label: 'Disputes', icon: FileWarning },
  { href: '/audit-logs', label: 'Audit Logs', icon: FileClock },
  { href: '/settings', label: 'Settings', icon: Settings },
];

export function AdminShell({ children }: { children: React.ReactNode }) {
  const showLogout =
    getAdminAuthMode() === 'supabase_role' || Boolean(process.env.ADMIN_ACCESS_CODE);

  return (
    <main className="min-h-screen">
      <div className="mx-auto flex max-w-7xl flex-col gap-4 px-4 py-4 sm:px-6 md:flex-row md:gap-6 md:py-6">
        <section className="rounded-lg border border-slate-200 bg-white p-4 md:hidden">
          <div className="flex items-start justify-between gap-4">
            <div>
              <h1 className="text-lg font-semibold text-slate-950">MediConnect</h1>
              <p className="mt-1 text-sm text-slate-500">Admin operations</p>
            </div>
            {showLogout ? (
              <form action={logoutAdmin}>
                <button
                  className="rounded-md border border-slate-200 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                  type="submit"
                >
                  Log out
                </button>
              </form>
            ) : null}
          </div>
          <nav className="mt-4 grid grid-cols-2 gap-2 text-sm min-[520px]:grid-cols-3" aria-label="Admin sections">
            {navItems.map((item) => (
              <Link
                className="flex items-center gap-2 rounded-md border border-slate-100 px-3 py-2 text-slate-700 hover:bg-slate-50"
                href={item.href}
                key={item.label}
              >
                <item.icon className="h-4 w-4 shrink-0" aria-hidden="true" />
                <span className="truncate">{item.label}</span>
              </Link>
            ))}
          </nav>
        </section>
        <aside className="hidden w-64 shrink-0 rounded-lg border border-slate-200 bg-white p-4 md:block">
          <h1 className="text-xl font-semibold text-slate-950">MediConnect</h1>
          <p className="mt-1 text-sm text-slate-500">Admin operations</p>
          <nav className="mt-8 space-y-1 text-sm" aria-label="Admin sections">
            {navItems.map((item) => (
              <Link
                className="flex items-center gap-2 rounded-md px-3 py-2 text-slate-700 hover:bg-slate-100"
                href={item.href}
                key={item.label}
              >
                <item.icon className="h-4 w-4" aria-hidden="true" />
                {item.label}
              </Link>
            ))}
          </nav>
          {showLogout ? (
            <form action={logoutAdmin} className="mt-8">
              <button
                className="w-full rounded-md border border-slate-200 px-3 py-2 text-left text-sm font-medium text-slate-700 hover:bg-slate-50"
                type="submit"
              >
                Log out
              </button>
            </form>
          ) : null}
        </aside>

        <section className="min-w-0 flex-1">{children}</section>
      </div>
    </main>
  );
}
