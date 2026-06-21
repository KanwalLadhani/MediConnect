const fs = require('node:fs');
const path = require('node:path');

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const PHONE_PATTERN = /^\+[1-9]\d{7,14}$/;

function parseEnvFile(contents) {
  const env = {};

  for (const rawLine of contents.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#') || !line.includes('=')) {
      continue;
    }

    const separator = line.indexOf('=');
    const key = line.slice(0, separator).trim();
    let value = line.slice(separator + 1).trim();
    if (
      value.length >= 2 &&
      ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'")))
    ) {
      value = value.slice(1, -1);
    }
    env[key] = value;
  }

  return env;
}

function validateSeedEnvironment(env) {
  const email = String(env.ADMIN_SEED_EMAIL ?? '').trim().toLowerCase();
  const password = String(env.ADMIN_SEED_PASSWORD ?? '');
  const fullName = String(env.ADMIN_SEED_FULL_NAME ?? '').trim();
  const phone = String(env.ADMIN_SEED_PHONE ?? '').trim();

  if (!EMAIL_PATTERN.test(email) || email.length > 254) {
    throw new Error('ADMIN_SEED_EMAIL must be a valid email address.');
  }
  if (
    password.length < 12 ||
    password.length > 128 ||
    !/[a-z]/.test(password) ||
    !/[A-Z]/.test(password) ||
    !/\d/.test(password) ||
    !/[^A-Za-z0-9]/.test(password)
  ) {
    throw new Error(
      'ADMIN_SEED_PASSWORD must be 12-128 characters with upper, lower, number, and symbol characters.',
    );
  }
  if (fullName.length < 2 || fullName.length > 100 || /[\r\n]/.test(fullName)) {
    throw new Error('ADMIN_SEED_FULL_NAME must be 2-100 characters on one line.');
  }
  if (!PHONE_PATTERN.test(phone)) {
    throw new Error('ADMIN_SEED_PHONE must use E.164 format, for example +923001234567.');
  }

  return { email, password, fullName, phone };
}

function loadSupabaseConfiguration(envFilePath) {
  if (!fs.existsSync(envFilePath)) {
    throw new Error('admin/.env.local is required.');
  }

  const localEnv = parseEnvFile(fs.readFileSync(envFilePath, 'utf8'));
  const supabaseUrl = localEnv.NEXT_PUBLIC_SUPABASE_URL?.trim();
  const serviceRoleKey = localEnv.SUPABASE_SERVICE_ROLE_KEY?.trim();

  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error(
      'NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required in admin/.env.local.',
    );
  }

  let parsedUrl;
  try {
    parsedUrl = new URL(supabaseUrl);
  } catch {
    throw new Error('NEXT_PUBLIC_SUPABASE_URL in admin/.env.local is invalid.');
  }
  if (parsedUrl.protocol !== 'https:' && !['localhost', '127.0.0.1'].includes(parsedUrl.hostname)) {
    throw new Error('NEXT_PUBLIC_SUPABASE_URL must use HTTPS unless it targets localhost.');
  }

  return { supabaseUrl, serviceRoleKey };
}

async function findAuthUserByEmail(client, email) {
  const matches = [];
  for (let page = 1; ; page += 1) {
    const { data, error } = await client.auth.admin.listUsers({ page, perPage: 1000 });
    if (error) {
      throw new Error('Unable to inspect Supabase Auth users.');
    }

    const users = data?.users ?? [];
    matches.push(
      ...users.filter((user) => user.email?.trim().toLowerCase() === email),
    );
    if (users.length < 1000) {
      break;
    }
  }

  if (matches.length > 1) {
    throw new Error('Multiple Supabase Auth users have the requested email.');
  }
  return matches[0] ?? null;
}

async function assertExistingUserCanBeReused(client, userId) {
  const { data: profile, error } = await client
    .from('profiles')
    .select('role, is_active')
    .eq('id', userId)
    .maybeSingle();

  if (error) {
    throw new Error('Unable to verify the existing user profile.');
  }
  if (profile && (profile.role !== 'admin' || profile.is_active !== true)) {
    throw new Error(
      'The requested email belongs to a non-admin or inactive account and cannot be reused.',
    );
  }
}

async function bootstrapAdmin(client, seed) {
  const existingUser = await findAuthUserByEmail(client, seed.email);
  let user;

  if (existingUser) {
    await assertExistingUserCanBeReused(client, existingUser.id);
    const { data, error } = await client.auth.admin.updateUserById(existingUser.id, {
      password: seed.password,
      email_confirm: true,
      user_metadata: { full_name: seed.fullName, phone: seed.phone },
    });
    if (error || !data?.user) {
      throw new Error('Unable to update the Supabase Auth user.');
    }
    user = data.user;
  } else {
    const { data, error } = await client.auth.admin.createUser({
      email: seed.email,
      password: seed.password,
      email_confirm: true,
      user_metadata: { full_name: seed.fullName, phone: seed.phone },
    });
    if (error || !data?.user) {
      throw new Error('Unable to create the Supabase Auth user.');
    }
    user = data.user;
  }

  const profile = {
    id: user.id,
    role: 'admin',
    full_name: seed.fullName,
    phone: seed.phone,
    email: seed.email,
    is_active: true,
  };
  const { error: upsertError } = await client.from('profiles').upsert(profile, {
    onConflict: 'id',
  });
  if (upsertError) {
    throw new Error('Unable to upsert the admin profile.');
  }

  const { data: storedProfile, error: verificationError } = await client
    .from('profiles')
    .select('id, email, role, is_active')
    .eq('id', user.id)
    .single();
  if (
    verificationError ||
    storedProfile?.id !== user.id ||
    storedProfile?.email?.trim().toLowerCase() !== seed.email ||
    storedProfile?.role !== 'admin' ||
    storedProfile?.is_active !== true
  ) {
    throw new Error('Admin profile verification failed.');
  }

  return user;
}

function maskEmail(email) {
  const [local, domain] = email.split('@');
  const maskedLocal = local.length <= 2
    ? `${local[0]}*`
    : `${local.slice(0, 2)}${'*'.repeat(Math.min(local.length - 2, 6))}`;
  return `${maskedLocal}@${domain}`;
}

function maskUserId(userId) {
  if (userId.length <= 8) {
    return '********';
  }
  return `${userId.slice(0, 4)}...${userId.slice(-4)}`;
}

async function main() {
  // Seed validation intentionally happens before config loading or any client/network work.
  const seed = validateSeedEnvironment(process.env);
  const envFilePath = path.join(__dirname, '..', '.env.local');
  const config = loadSupabaseConfiguration(envFilePath);
  const { createClient } = require('@supabase/supabase-js');
  const client = createClient(config.supabaseUrl, config.serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const user = await bootstrapAdmin(client, seed);

  console.log(
    `Admin bootstrap verified: email=${maskEmail(seed.email)} user=${maskUserId(user.id)}`,
  );
}

if (require.main === module) {
  main().catch((error) => {
    console.error(`Admin bootstrap failed: ${error.message}`);
    process.exitCode = 1;
  });
}

module.exports = {
  assertExistingUserCanBeReused,
  bootstrapAdmin,
  findAuthUserByEmail,
  loadSupabaseConfiguration,
  maskEmail,
  maskUserId,
  parseEnvFile,
  validateSeedEnvironment,
};
