export type DeploymentHealthStatus = 'ok' | 'misconfigured';

export function deploymentHealthStatus(
  env: Record<string, string | undefined>,
): DeploymentHealthStatus {
  const requiredValues = [
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    env.SUPABASE_SERVICE_ROLE_KEY,
  ];

  if (env.ADMIN_AUTH_MODE === 'supabase_role') {
    requiredValues.push(env.ADMIN_SESSION_SECRET);
  }

  return requiredValues.every((value) => Boolean(value?.trim()))
    ? 'ok'
    : 'misconfigured';
}
