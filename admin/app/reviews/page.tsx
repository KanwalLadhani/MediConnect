import Link from 'next/link';
import { Star, TriangleAlert } from 'lucide-react';

import { AdminShell } from '../components/admin-shell';
import { EmptyState, MetricCard } from '../components/admin-ui';
import { getAdminReviewAnalytics, getAdminReviews } from '@/lib/admin-data';

export const dynamic = 'force-dynamic';

export default async function ReviewsPage() {
  const [reviews, analytics] = await Promise.all([
    getAdminReviews(),
    getAdminReviewAnalytics(),
  ]);

  return (
    <AdminShell>
      <div className="rounded-lg border border-slate-200 bg-white p-6">
        <p className="text-sm font-medium uppercase tracking-wide text-brand-700">Patient feedback</p>
        <h2 className="mt-2 text-3xl font-semibold text-slate-950">Reviews</h2>
        <p className="mt-2 max-w-2xl text-slate-600">
          Inspect patient ratings, worker feedback, and low-score service quality signals.
        </p>
      </div>

      <div className="mt-6 grid gap-4 md:grid-cols-3">
        <MetricCard icon={Star} label="Total reviews" value={analytics.totalReviews.toString()} />
        <MetricCard icon={Star} label="Average rating" value={analytics.averageRating.toFixed(2)} />
        <MetricCard icon={TriangleAlert} label="Low ratings" value={analytics.lowRatingCount.toString()} />
      </div>

      <div className="mt-6 overflow-hidden rounded-lg border border-slate-200 bg-white">
        {reviews.length === 0 ? (
          <EmptyState
            title="No reviews yet"
            description="Patient reviews will appear after completed orders."
          />
        ) : (
          <div className="divide-y divide-slate-200">
            {reviews.map((review) => {
              const request = review.orders?.service_requests;
              return (
                <article className="p-5" key={review.id}>
                  <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                    <div className="min-w-0">
                      <div className="flex flex-wrap items-center gap-2">
                        <h3 className="min-w-0 break-words text-lg font-semibold text-slate-950">
                          {request?.service_categories?.name_en ?? 'Service'}
                        </h3>
                        <span className="rounded-full bg-amber-50 px-2 py-1 text-xs font-medium text-amber-800">
                          {review.rating}/5
                        </span>
                      </div>
                      <p className="mt-2 break-words text-sm text-slate-600">
                        Patient: {review.patients?.profiles?.full_name ?? 'Patient'} - Worker:{' '}
                        {review.health_workers?.profiles?.full_name ?? 'Worker'}
                      </p>
                      <p className="mt-1 break-words text-sm text-slate-500">
                        {request?.locations?.address ?? 'Address not set'}, {request?.locations?.city ?? 'City'}
                      </p>
                      <p className="mt-3 max-w-2xl text-sm text-slate-700">
                        {review.review_text ?? 'No written review.'}
                      </p>
                    </div>
                    <div className="w-full rounded-md bg-slate-50 px-4 py-3 text-sm text-slate-700 lg:w-52">
                      <p className="font-medium text-slate-950">Order</p>
                      <p className="mt-1 break-words">{review.orders?.status ?? 'unknown'}</p>
                      <p className="mt-1 break-words">PKR {review.orders?.final_price_pkr?.toLocaleString() ?? '0'}</p>
                      {review.orders?.id ? (
                        <Link
                          className="mt-3 inline-flex rounded-md bg-brand-700 px-3 py-2 text-sm font-medium text-white hover:bg-brand-800"
                          href={`/orders/${review.orders.id}`}
                        >
                          Open trace
                        </Link>
                      ) : null}
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
