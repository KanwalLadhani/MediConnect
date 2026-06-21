export type AdminServiceStatusInput = {
  categoryId: string;
  isActive: boolean;
};

export function parseServiceStatusForm(formData: FormData): AdminServiceStatusInput {
  return assertValidServiceStatus({
    categoryId: String(formData.get('categoryId') ?? ''),
    isActive: String(formData.get('isActive')) === 'true',
  });
}

export function assertValidServiceStatus(
  input: AdminServiceStatusInput,
): AdminServiceStatusInput {
  const categoryId = input.categoryId.trim();

  if (!categoryId) {
    throw new Error('Missing service category.');
  }

  return {
    categoryId,
    isActive: input.isActive,
  };
}
