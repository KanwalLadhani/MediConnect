export type AdminDisputeReviewStatus = 'reviewing' | 'resolved' | 'rejected';

export type AdminDisputeReviewInput = {
  disputeId: string;
  status: AdminDisputeReviewStatus;
  resolutionNotes?: string;
};

const allowedStatuses = new Set<AdminDisputeReviewStatus>([
  'reviewing',
  'resolved',
  'rejected',
]);

export function parseDisputeReviewForm(
  formData: FormData,
  status: AdminDisputeReviewStatus,
): AdminDisputeReviewInput {
  return assertValidDisputeReview({
    disputeId: String(formData.get('disputeId') ?? ''),
    status,
    resolutionNotes: String(formData.get('resolutionNotes') ?? ''),
  });
}

export function assertValidDisputeReview(
  input: AdminDisputeReviewInput,
): AdminDisputeReviewInput {
  const disputeId = input.disputeId.trim();
  const resolutionNotes = input.resolutionNotes?.trim();

  if (!disputeId) {
    throw new Error('Missing dispute.');
  }

  if (!allowedStatuses.has(input.status)) {
    throw new Error('Invalid dispute review status.');
  }

  return {
    disputeId,
    status: input.status,
    resolutionNotes: resolutionNotes || undefined,
  };
}
