export type SafeAuditMetadataItem = {
  label: string;
  value: string;
};

const sensitiveKeyPattern =
  /(access|account|body|code|description|detail|file|image|key|message|note|password|path|reason|reference|screenshot|secret|service_role|signed|text|token|url)/i;

const safeStringKeyPattern =
  /(^id$|_id$|^status$|_status$|^state$|_state$|^role$|_role$|^type$|_type$)/i;

const safeNumberKeyPattern = /(^count$|_count$|^total$|_total$)/i;

export function sanitizeAuditMetadata(
  metadata: Record<string, unknown> | null | undefined,
): SafeAuditMetadataItem[] {
  if (!metadata || typeof metadata !== 'object') {
    return [];
  }

  return Object.entries(metadata).flatMap(([key, value]) => {
    if (sensitiveKeyPattern.test(key)) {
      return [];
    }

    if (typeof value === 'boolean') {
      return [{ label: labelizeMetadataKey(key), value: value ? 'Yes' : 'No' }];
    }

    if (typeof value === 'string' && safeStringKeyPattern.test(key)) {
      const trimmed = value.trim();
      return trimmed ? [{ label: labelizeMetadataKey(key), value: compactValue(trimmed) }] : [];
    }

    if (typeof value === 'number' && safeNumberKeyPattern.test(key)) {
      return Number.isFinite(value)
        ? [{ label: labelizeMetadataKey(key), value: value.toLocaleString() }]
        : [];
    }

    return [];
  });
}

function labelizeMetadataKey(key: string) {
  return key
    .replaceAll('_', ' ')
    .replace(/\b\w/g, (match) => match.toUpperCase());
}

function compactValue(value: string) {
  if (value.length <= 48) {
    return value;
  }

  return `${value.slice(0, 20)}...${value.slice(-12)}`;
}
