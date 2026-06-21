export type WalletTopUpReviewInput = {
  transactionId: string;
  approved: boolean;
};

export function parseWalletTopUpReviewForm(
  formData: FormData,
  approved: boolean,
): WalletTopUpReviewInput {
  return assertValidWalletTopUpReview({
    transactionId: String(formData.get('transactionId') ?? ''),
    approved,
  });
}

export function assertValidWalletTopUpReview(
  input: WalletTopUpReviewInput,
): WalletTopUpReviewInput {
  const transactionId = input.transactionId.trim();

  if (!transactionId) {
    throw new Error('Missing wallet top-up transaction.');
  }

  return {
    transactionId,
    approved: input.approved,
  };
}
