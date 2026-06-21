export type AdminWorkerVerificationStatus = 'approved' | 'rejected';

export type AdminWorkerVerificationInput = {
  workerId: string;
  status: AdminWorkerVerificationStatus;
  rejectionReason?: string;
};

const defaultRejectionReason = 'Documents or profile details need correction.';

export function parseWorkerVerificationForm(
  formData: FormData,
  status: AdminWorkerVerificationStatus,
): AdminWorkerVerificationInput {
  return assertValidWorkerVerification({
    workerId: String(formData.get('workerId') ?? ''),
    status,
    rejectionReason: String(formData.get('rejectionReason') ?? ''),
  });
}

export function assertValidWorkerVerification(
  input: AdminWorkerVerificationInput,
): AdminWorkerVerificationInput {
  const workerId = input.workerId.trim();
  const rejectionReason = input.rejectionReason?.trim();

  if (!workerId) {
    throw new Error('Missing worker.');
  }

  if (input.status !== 'approved' && input.status !== 'rejected') {
    throw new Error('Invalid worker verification status.');
  }

  return {
    workerId,
    status: input.status,
    rejectionReason:
      input.status === 'rejected'
        ? rejectionReason || defaultRejectionReason
        : undefined,
  };
}
