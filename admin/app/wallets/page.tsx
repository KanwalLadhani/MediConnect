import { revalidatePath } from 'next/cache';
import { CreditCard, ExternalLink, ImageIcon } from 'lucide-react';

import { AdminShell } from '../components/admin-shell';
import { EmptyState } from '../components/admin-ui';
import { getPendingWalletTopUps, reviewWalletTopUp } from '@/lib/admin-data';
import { parseWalletTopUpReviewForm } from '@/lib/admin-wallet-review';

export const dynamic = 'force-dynamic';

async function approveTopUp(formData: FormData) {
  'use server';

  await reviewWalletTopUp(parseWalletTopUpReviewForm(formData, true));
  revalidatePath('/wallets');
}

async function rejectTopUp(formData: FormData) {
  'use server';

  await reviewWalletTopUp(parseWalletTopUpReviewForm(formData, false));
  revalidatePath('/wallets');
}

export default async function WalletsPage() {
  const topUps = await getPendingWalletTopUps();

  return (
    <AdminShell>
      <div className="rounded-lg border border-slate-200 bg-white p-6">
        <p className="text-sm font-medium uppercase tracking-wide text-brand-700">Wallet operations</p>
        <h2 className="mt-2 text-3xl font-semibold text-slate-950">Top-up approvals</h2>
        <p className="mt-2 max-w-2xl text-slate-600">
          Review manual JazzCash and EasyPaisa references before crediting worker wallets.
        </p>
      </div>

      <div className="mt-6 overflow-hidden rounded-lg border border-slate-200 bg-white">
        {topUps.length === 0 ? (
          <EmptyState
            title="No pending top-ups"
            description="New worker wallet requests will appear here."
          />
        ) : (
          <div className="divide-y divide-slate-200">
            {topUps.map((topUp) => {
              const worker = topUp.wallets?.health_workers;
              const profile = worker?.profiles;
              return (
                <article className="p-5" key={topUp.id}>
                  <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                    <div className="min-w-0">
                      <div className="flex items-center gap-2">
                        <CreditCard className="h-5 w-5 shrink-0 text-brand-700" aria-hidden="true" />
                        <h3 className="min-w-0 break-words text-lg font-semibold text-slate-950">
                          PKR {topUp.amount_pkr.toLocaleString()}
                        </h3>
                      </div>
                      <p className="mt-2 break-words text-sm text-slate-600">
                        {profile?.full_name ?? 'Worker'} - {worker?.worker_type?.replaceAll('_', ' ') ?? 'health worker'}
                      </p>
                      <p className="mt-1 text-sm text-slate-500">
                        Current balance: PKR {topUp.wallets?.balance_pkr?.toLocaleString() ?? '0'}
                      </p>
                      <p className="mt-3 break-words text-sm text-slate-700">
                        Reference: {topUp.reference ?? 'No reference provided'}
                      </p>
                      {topUp.screenshot_path ? (
                        <div className="mt-2 flex flex-col gap-2 text-sm text-slate-500">
                          <p className="flex items-center gap-2 break-all">
                            <ImageIcon className="h-4 w-4 shrink-0" />
                            {topUp.screenshot_path}
                          </p>
                          {topUp.screenshotSignedUrl ? (
                            <a
                              className="inline-flex w-fit items-center gap-1 rounded-md border border-slate-200 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                              href={topUp.screenshotSignedUrl}
                              rel="noreferrer"
                              target="_blank"
                            >
                              <ExternalLink className="h-4 w-4" />
                              Open screenshot
                            </a>
                          ) : null}
                        </div>
                      ) : null}
                    </div>

                    <div className="flex w-full flex-col gap-2 lg:w-52">
                      <form action={approveTopUp}>
                        <input name="transactionId" type="hidden" value={topUp.id} />
                        <button
                          className="w-full rounded-md bg-emerald-700 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-800"
                          type="submit"
                        >
                          Approve top-up
                        </button>
                      </form>
                      <form action={rejectTopUp}>
                        <input name="transactionId" type="hidden" value={topUp.id} />
                        <button
                          className="w-full rounded-md border border-rose-200 px-4 py-2 text-sm font-medium text-rose-700 hover:bg-rose-50"
                          type="submit"
                        >
                          Reject
                        </button>
                      </form>
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
