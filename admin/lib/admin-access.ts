export const adminCookieName = 'mediconnect_admin_access';

export type AdminAuthMode = 'access_code' | 'supabase_role';

export function getAdminAuthMode(): AdminAuthMode {
  return process.env.ADMIN_AUTH_MODE === 'supabase_role'
    ? 'supabase_role'
    : 'access_code';
}

export function isAdminSessionSecretConfigured() {
  return Boolean(process.env.ADMIN_SESSION_SECRET?.trim());
}

export async function createAdminAccessToken(accessCode: string) {
  const secret = [
    'access-code',
    accessCode,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    process.env.NEXT_PUBLIC_SUPABASE_URL,
  ]
    .filter(Boolean)
    .join(':');

  const bytes = new TextEncoder().encode(secret);
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

export async function isValidAdminAccessToken(token: string | undefined, accessCode: string) {
  if (!token) {
    return false;
  }

  const expectedToken = await createAdminAccessToken(accessCode);
  return token === expectedToken;
}

export async function createAdminRoleCookieValue(userId: string) {
  if (!isAdminSessionSecretConfigured()) {
    throw new Error('ADMIN_SESSION_SECRET is required for Supabase admin-role mode.');
  }

  const token = await createAdminRoleAccessToken(userId);
  return `${userId}.${token}`;
}

export async function isValidAdminRoleCookieValue(cookieValue: string | undefined) {
  if (!isAdminSessionSecretConfigured()) {
    return false;
  }

  if (!cookieValue) {
    return false;
  }

  const [userId, token] = cookieValue.split('.');
  if (!userId || !token) {
    return false;
  }

  const expectedToken = await createAdminRoleAccessToken(userId);
  return token === expectedToken;
}

async function createAdminRoleAccessToken(userId: string) {
  const secret = [
    'supabase-admin-role',
    userId,
    process.env.ADMIN_SESSION_SECRET,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    process.env.NEXT_PUBLIC_SUPABASE_URL,
  ]
    .filter(Boolean)
    .join(':');

  const bytes = new TextEncoder().encode(secret);
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}
