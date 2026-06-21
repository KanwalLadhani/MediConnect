import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { createClient } from '@supabase/supabase-js';
import { LockKeyhole } from 'lucide-react';

import {
  adminCookieName,
  createAdminAccessToken,
  createAdminRoleCookieValue,
  getAdminAuthMode,
  isAdminSessionSecretConfigured,
} from '@/lib/admin-access';
import { createSupabaseClient } from '@/lib/supabase';

async function login(formData: FormData) {
  'use server';

  const mode = getAdminAuthMode();
  if (mode === 'supabase_role') {
    await loginWithSupabaseAdminRole(formData);
    return;
  }

  const configuredCode = process.env.ADMIN_ACCESS_CODE;
  const submittedCode = String(formData.get('accessCode') ?? '');
  const nextPath = sanitizeNextPath(String(formData.get('next') ?? '/'));

  if (!configuredCode) {
    redirect(nextPath);
  }

  if (submittedCode !== configuredCode) {
    redirect(`/login?error=1&next=${encodeURIComponent(nextPath)}`);
  }

  const cookieStore = await cookies();
  cookieStore.set(adminCookieName, await createAdminAccessToken(configuredCode), {
    httpOnly: true,
    maxAge: 60 * 60 * 12,
    path: '/',
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
  });

  redirect(nextPath);
}

async function loginWithSupabaseAdminRole(formData: FormData) {
  const nextPath = sanitizeNextPath(String(formData.get('next') ?? '/'));
  const email = String(formData.get('email') ?? '').trim();
  const password = String(formData.get('password') ?? '');
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const serviceClient = createSupabaseClient();

  if (
    !supabaseUrl ||
    !supabaseAnonKey ||
    !supabaseServiceRoleKey ||
    !serviceClient ||
    !isAdminSessionSecretConfigured()
  ) {
    redirect(`/login?error=configuration&next=${encodeURIComponent(nextPath)}`);
  }

  const authClient = createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });

  const { data, error } = await authClient.auth.signInWithPassword({
    email,
    password,
  });

  if (error || !data.user) {
    redirect(`/login?error=credentials&next=${encodeURIComponent(nextPath)}`);
  }

  const { data: profile, error: profileError } = await serviceClient
    .from('profiles')
    .select('role')
    .eq('id', data.user.id)
    .maybeSingle();

  if (profileError || profile?.role !== 'admin') {
    redirect(`/login?error=role&next=${encodeURIComponent(nextPath)}`);
  }

  const cookieStore = await cookies();
  cookieStore.set(adminCookieName, await createAdminRoleCookieValue(data.user.id), {
    httpOnly: true,
    maxAge: 60 * 60 * 12,
    path: '/',
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
  });

  redirect(nextPath);
}

export default async function AdminLoginPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string; next?: string }>;
}) {
  const params = await searchParams;
  const nextPath = sanitizeNextPath(params.next ?? '/');
  const mode = getAdminAuthMode();

  if (mode === 'access_code' && !process.env.ADMIN_ACCESS_CODE) {
    redirect(nextPath);
  }

  return (
    <main className="flex min-h-screen items-center justify-center px-6 py-10">
      <section className="w-full max-w-md rounded-lg border border-slate-200 bg-white p-6">
        <div className="flex h-11 w-11 items-center justify-center rounded-lg bg-brand-50 text-brand-700">
          <LockKeyhole className="h-5 w-5" />
        </div>
        <p className="mt-5 text-sm font-medium uppercase tracking-wide text-brand-700">Admin access</p>
        <h1 className="mt-2 text-2xl font-semibold text-slate-950">MediConnect Admin</h1>
        <p className="mt-2 text-sm text-slate-600">
          {mode === 'supabase_role'
            ? 'Sign in with a Supabase Auth user whose profile role is admin.'
            : 'Enter the admin access code configured for this environment.'}
        </p>

        {params.error ? (
          <p className="mt-4 rounded-md bg-rose-50 px-3 py-2 text-sm text-rose-800" role="alert">
            {errorMessage(params.error, mode)}
          </p>
        ) : null}

        <form action={login} className="mt-5 space-y-4">
          <input name="next" type="hidden" value={nextPath} />
          {mode === 'supabase_role' ? (
            <>
              <div>
                <label className="block text-sm font-medium text-slate-700" htmlFor="email">
                  Email
                </label>
                <input
                  autoComplete="email"
                  autoFocus
                  className="mt-2 w-full rounded-md border border-slate-300 px-3 py-2 text-sm outline-none focus:border-brand-700 focus:ring-2 focus:ring-brand-100"
                  id="email"
                  name="email"
                  required
                  type="email"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700" htmlFor="password">
                  Password
                </label>
                <input
                  autoComplete="current-password"
                  className="mt-2 w-full rounded-md border border-slate-300 px-3 py-2 text-sm outline-none focus:border-brand-700 focus:ring-2 focus:ring-brand-100"
                  id="password"
                  name="password"
                  required
                  type="password"
                />
              </div>
            </>
          ) : (
            <>
              <div>
                <label className="block text-sm font-medium text-slate-700" htmlFor="accessCode">
                  Access code
                </label>
                <input
                  autoComplete="current-password"
                  autoFocus
                  className="mt-2 w-full rounded-md border border-slate-300 px-3 py-2 text-sm outline-none focus:border-brand-700 focus:ring-2 focus:ring-brand-100"
                  id="accessCode"
                  name="accessCode"
                  required
                  type="password"
                />
              </div>
            </>
          )}
          <button
            className="min-h-10 w-full rounded-md bg-brand-700 px-4 py-2 text-sm font-medium text-white hover:bg-brand-800"
            type="submit"
          >
            {mode === 'supabase_role' ? 'Sign in' : 'Unlock admin'}
          </button>
        </form>
      </section>
    </main>
  );
}

function sanitizeNextPath(value: string) {
  if (!value.startsWith('/') || value.startsWith('//')) {
    return '/';
  }

  if (value.startsWith('/login')) {
    return '/';
  }

  return value;
}

function errorMessage(error: string, mode: 'access_code' | 'supabase_role') {
  if (mode === 'access_code') {
    return 'Incorrect access code.';
  }

  if (error === 'configuration') {
    return 'Supabase admin login is not fully configured.';
  }

  if (error === 'role') {
    return 'This account does not have the admin role.';
  }

  return 'Incorrect email or password.';
}
