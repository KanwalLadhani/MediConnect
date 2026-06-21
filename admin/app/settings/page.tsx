import {
  CheckCircle2,
  CircleAlert,
  ExternalLink,
  KeyRound,
  Map,
  ShieldCheck,
  Smartphone,
  Server,
  Trash2,
} from 'lucide-react';
import Link from 'next/link';

import { AdminShell } from '../components/admin-shell';
import { getAdminAuthMode, isAdminSessionSecretConfigured } from '@/lib/admin-access';
import { isSupabaseConfigured } from '@/lib/supabase';

export const dynamic = 'force-dynamic';

const envStatus = [
  {
    label: 'Supabase URL',
    value: process.env.NEXT_PUBLIC_SUPABASE_URL ?? '',
    configured: Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL),
    icon: Server,
    isSecret: false,
  },
  {
    label: 'Supabase anon key',
    value: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? '',
    configured: Boolean(process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY),
    icon: KeyRound,
    isSecret: true,
  },
  {
    label: 'Supabase service role key',
    value: process.env.SUPABASE_SERVICE_ROLE_KEY ?? '',
    configured: Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY),
    icon: KeyRound,
    isSecret: true,
  },
  {
    label: 'Maps API key',
    value: process.env.NEXT_PUBLIC_MAPS_API_KEY ?? '',
    configured: Boolean(process.env.NEXT_PUBLIC_MAPS_API_KEY),
    icon: Map,
    isSecret: true,
  },
  {
    label: 'Admin app URL',
    value: process.env.ADMIN_APP_URL ?? '',
    configured: Boolean(process.env.ADMIN_APP_URL),
    icon: Server,
    isSecret: false,
  },
  {
    label: 'Admin access code',
    value: process.env.ADMIN_ACCESS_CODE ?? '',
    configured: Boolean(process.env.ADMIN_ACCESS_CODE),
    icon: KeyRound,
    isSecret: true,
  },
  {
    label: 'Admin auth mode',
    value: process.env.ADMIN_AUTH_MODE ?? 'access_code',
    configured: true,
    icon: KeyRound,
    isSecret: false,
  },
  {
    label: 'Admin session secret',
    value: process.env.ADMIN_SESSION_SECRET ?? '',
    configured: Boolean(process.env.ADMIN_SESSION_SECRET),
    icon: KeyRound,
    isSecret: true,
  },
];

const requiredBackendMigrations = [
  '20260613140000_initial_schema.sql',
  '20260613170000_service_request_images_bucket.sql',
  '20260613173000_service_request_offers.sql',
  '20260614090000_reviews_and_disputes.sql',
  '20260614103000_chat_image_participant_read.sql',
  '20260615120000_wallet_top_up_review_rpc.sql',
  '20260615123000_order_status_update_rpc.sql',
  '20260615130000_admin_audit_logs.sql',
  '20260617110000_worker_distance_matching.sql',
];

export default function SettingsPage() {
  const adminAuthMode = getAdminAuthMode();
  const isAccessCodeMode = adminAuthMode === 'access_code';
  const supabaseAdminRoleReady =
    adminAuthMode === 'supabase_role' &&
    isSupabaseConfigured &&
    Boolean(process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) &&
    Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY) &&
    isAdminSessionSecretConfigured();

  return (
    <AdminShell>
      <div className="rounded-lg border border-slate-200 bg-white p-6">
        <p className="text-sm font-medium uppercase tracking-wide text-brand-700">Deployment readiness</p>
        <h2 className="mt-2 text-3xl font-semibold text-slate-950">Settings</h2>
        <p className="mt-2 max-w-2xl text-slate-600">
          Check environment configuration for local testing and future deployment. Secret values are never displayed.
        </p>
      </div>

      <div className="mt-6 rounded-lg border border-slate-200 bg-white p-5">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h3 className="text-lg font-semibold text-slate-950">Supabase connection</h3>
            <p className="mt-1 text-sm text-slate-600">
              Admin operations need the project URL and service role key on the server.
            </p>
          </div>
          <StatusBadge ok={isSupabaseConfigured} label={isSupabaseConfigured ? 'Configured' : 'Missing'} />
        </div>
      </div>

      <div className="mt-6 grid gap-4 lg:grid-cols-2">
        {envStatus.map((item) => (
          <article className="rounded-lg border border-slate-200 bg-white p-5" key={item.label}>
            <div className="flex items-start justify-between gap-4">
              <div className="flex items-center gap-3">
                <item.icon className="h-5 w-5 text-brand-700" />
                <div>
                  <h3 className="font-semibold text-slate-950">{item.label}</h3>
                  <p className="mt-1 text-sm text-slate-600">
                    {item.configured ? displayValue(item.value, item.isSecret) : 'Not set'}
                  </p>
                </div>
              </div>
              <StatusBadge ok={item.configured} label={item.configured ? 'Set' : 'Missing'} />
            </div>
          </article>
        ))}
      </div>

      <div className="mt-6 rounded-lg border border-slate-200 bg-white p-5">
        <div className="flex items-start gap-3">
          <Server className="mt-1 h-5 w-5 text-brand-700" />
          <div>
            <h3 className="text-lg font-semibold text-slate-950">Backend migration readiness</h3>
            <p className="mt-1 text-sm text-slate-600">
              Apply these Supabase migrations in order before live end-to-end testing. This page does not check the
              remote database directly; it is the required deployment checklist from the repo.
            </p>
          </div>
        </div>
        <div className="mt-4 grid gap-2 lg:grid-cols-2">
          {requiredBackendMigrations.map((migration) => (
            <div
              className="flex items-center gap-2 rounded-md bg-slate-50 px-3 py-2 text-sm text-slate-700"
              key={migration}
            >
              <CheckCircle2 className="h-4 w-4 text-emerald-700" />
              <span className="break-all font-mono text-xs">{migration}</span>
            </div>
          ))}
        </div>
        <div className="mt-4 grid gap-3 md:grid-cols-2 lg:grid-cols-4">
          <ChecklistItem done={true} label="review_wallet_top_up RPC required" />
          <ChecklistItem done={true} label="update_order_status_with_event RPC required" />
          <ChecklistItem done={true} label="audit_logs table required" />
          <ChecklistItem done={true} label="find_available_workers_for_request RPC required" />
        </div>
      </div>

      <div className="mt-6 rounded-lg border border-slate-200 bg-white p-5">
        <h3 className="text-lg font-semibold text-slate-950">Launch checklist</h3>
        <p className="mt-1 text-sm text-slate-600">
          Local MVP testing can use the access-code gate. Public deployment still needs Supabase admin-role authentication,
          Android signing, Maps key setup if a real map is enabled, and final demo-data cleanup.
        </p>
        <div className="mt-4 grid gap-3 md:grid-cols-2">
          <ChecklistItem done={isSupabaseConfigured} label="Live Supabase values configured" />
          <ChecklistItem done={Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY)} label="Service role key server-only" />
          <ChecklistItem done={isAccessCodeMode && Boolean(process.env.ADMIN_ACCESS_CODE)} label="MVP admin access-code gate enabled" />
          <ChecklistItem done={isAdminSessionSecretConfigured()} label="Admin session secret configured" />
          <ChecklistItem done={isAccessCodeMode || isAdminSessionSecretConfigured()} label="Admin cookie stores derived token" />
          <ChecklistItem done={supabaseAdminRoleReady} label="Supabase admin role enforcement" />
          <ChecklistItem done={Boolean(process.env.NEXT_PUBLIC_MAPS_API_KEY)} label="Maps API key for real map UI" />
          <ChecklistItem done={false} label="Delete demo/test data and helper test scripts" />
          <ChecklistItem done={false} label="Deploy admin to Vercel or chosen host" />
          <ChecklistItem done={false} label="Prepare Android internal testing build" />
        </div>
        <Link
          className="mt-5 inline-flex items-center gap-2 rounded-md border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
          href="/"
        >
          <ExternalLink className="h-4 w-4" />
          Back to dashboard
        </Link>
      </div>

      <div className="mt-6 grid gap-4 xl:grid-cols-2">
        <ReadinessSection
          icon={ShieldCheck}
          title="Security readiness"
          description="Public launch should not rely only on the MVP access-code gate."
          items={[
            {
              label: 'Supabase RLS policies are applied from migrations',
              status: 'ready',
            },
            {
              label: 'Service role key stays server-side in the admin app',
              status: process.env.SUPABASE_SERVICE_ROLE_KEY ? 'ready' : 'blocked',
            },
            {
              label: isAccessCodeMode
                ? 'Switch to Supabase admin-role login before public deployment'
                : 'Supabase admin-role login mode enabled',
              status: supabaseAdminRoleReady ? 'ready' : 'manual',
            },
            {
              label: 'ADMIN_SESSION_SECRET required before admin-role cookies are accepted',
              status: isAdminSessionSecretConfigured() ? 'ready' : 'manual',
            },
            {
              label: 'Run final live RLS/access test pass for patient, worker, and admin roles',
              status: 'manual',
            },
          ]}
        />

        <ReadinessSection
          icon={Trash2}
          title="Data cleanup readiness"
          description="Demo accounts and live-test helper scripts must remain until final validation is complete."
          items={[
            {
              label: 'Cleanup SQL exists: supabase/cleanup_test_data_before_launch.sql',
              status: 'ready',
            },
            {
              label: 'Run cleanup SQL only at final launch',
              status: 'manual',
            },
            {
              label: 'Delete live-test helper scripts after cleanup',
              status: 'manual',
            },
          ]}
        />

        <ReadinessSection
          icon={Map}
          title="Maps readiness"
          description="Current MVP uses a map-style status panel until a real Maps API key is provided."
          items={[
            {
              label: process.env.NEXT_PUBLIC_MAPS_API_KEY
                ? 'Maps API key configured'
                : 'Maps key only needed when replacing the current location panel',
              status: process.env.NEXT_PUBLIC_MAPS_API_KEY ? 'ready' : 'optional',
            },
            {
              label: 'Keep current location panel for internal MVP testing',
              status: 'ready',
            },
          ]}
        />

        <ReadinessSection
          icon={Smartphone}
          title="Deployment readiness"
          description="The app targets Android first, with admin hosting expected on Vercel or an equivalent host."
          items={[
            {
              label: 'Admin production build passes locally',
              status: 'ready',
            },
            {
              label: 'Deploy admin to Vercel or chosen host',
              status: 'manual',
            },
            {
              label: 'Create Android package name and signing keystore',
              status: 'manual',
            },
            {
              label: 'Build Android internal testing release',
              status: 'manual',
            },
          ]}
        />
      </div>
    </AdminShell>
  );
}

function StatusBadge({ ok, label }: { ok: boolean; label: string }) {
  return (
    <span
      className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-medium ${
        ok ? 'bg-emerald-50 text-emerald-800' : 'bg-amber-50 text-amber-800'
      }`}
    >
      {ok ? <CheckCircle2 className="h-3.5 w-3.5" /> : <CircleAlert className="h-3.5 w-3.5" />}
      {label}
    </span>
  );
}

function ChecklistItem({ done, label }: { done: boolean; label: string }) {
  return (
    <div className="flex items-center gap-2 rounded-md bg-slate-50 px-3 py-2 text-sm text-slate-700">
      {done ? (
        <CheckCircle2 className="h-4 w-4 text-emerald-700" />
      ) : (
        <CircleAlert className="h-4 w-4 text-amber-700" />
      )}
      {label}
    </div>
  );
}

type ReadinessStatus = 'ready' | 'manual' | 'optional' | 'blocked';

function ReadinessSection({
  icon: Icon,
  title,
  description,
  items,
}: {
  icon: React.ComponentType<{ className?: string }>;
  title: string;
  description: string;
  items: { label: string; status: ReadinessStatus }[];
}) {
  return (
    <section className="rounded-lg border border-slate-200 bg-white p-5">
      <div className="flex items-start gap-3">
        <Icon className="mt-1 h-5 w-5 text-brand-700" />
        <div>
          <h3 className="text-lg font-semibold text-slate-950">{title}</h3>
          <p className="mt-1 text-sm text-slate-600">{description}</p>
        </div>
      </div>
      <div className="mt-4 space-y-2">
        {items.map((item) => (
          <div className="flex items-center justify-between gap-3 rounded-md bg-slate-50 px-3 py-2 text-sm" key={item.label}>
            <span className="text-slate-700">{item.label}</span>
            <ReadinessBadge status={item.status} />
          </div>
        ))}
      </div>
    </section>
  );
}

function ReadinessBadge({ status }: { status: ReadinessStatus }) {
  const config = {
    ready: {
      label: 'Ready',
      className: 'bg-emerald-50 text-emerald-800',
    },
    manual: {
      label: 'Manual',
      className: 'bg-amber-50 text-amber-800',
    },
    optional: {
      label: 'Optional',
      className: 'bg-sky-50 text-sky-800',
    },
    blocked: {
      label: 'Missing',
      className: 'bg-rose-50 text-rose-800',
    },
  }[status];

  return (
    <span className={`shrink-0 rounded-full px-2 py-1 text-xs font-medium ${config.className}`}>
      {config.label}
    </span>
  );
}

function displayValue(value: string, isSecret: boolean) {
  if (!isSecret) {
    return value;
  }

  return 'Configured';
}
