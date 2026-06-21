'use client';

import { useEffect } from 'react';
import { CircleAlert, RefreshCw } from 'lucide-react';

export default function AdminError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <main className="flex min-h-screen items-center justify-center px-6 py-10">
      <section className="w-full max-w-lg rounded-lg border border-slate-200 bg-white p-6 text-center">
        <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-lg bg-amber-50 text-amber-700">
          <CircleAlert className="h-6 w-6" />
        </div>
        <h1 className="mt-5 text-2xl font-semibold text-slate-950">Admin page could not load</h1>
        <p className="mt-2 text-sm leading-6 text-slate-600">
          Check the Supabase connection and try again. If this keeps happening, use Settings to verify environment
          values and confirm the live database is reachable.
        </p>
        {error.digest ? <p className="mt-3 text-xs text-slate-400">Error reference: {error.digest}</p> : null}
        <button
          className="mt-5 inline-flex items-center gap-2 rounded-md bg-brand-700 px-4 py-2 text-sm font-medium text-white hover:bg-brand-800"
          onClick={reset}
          type="button"
        >
          <RefreshCw className="h-4 w-4" />
          Retry
        </button>
      </section>
    </main>
  );
}
