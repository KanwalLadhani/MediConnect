const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const {
  bootstrapAdmin,
  loadSupabaseConfiguration,
  maskEmail,
  maskUserId,
  validateSeedEnvironment,
} = require('./bootstrap-admin.cjs');

const validSeed = {
  ADMIN_SEED_EMAIL: 'First.Admin@example.com',
  ADMIN_SEED_PASSWORD: 'StrongPassword1!',
  ADMIN_SEED_FULL_NAME: 'First Admin',
  ADMIN_SEED_PHONE: '+923001234567',
};

test('seed validation normalizes valid input and rejects every invalid field', () => {
  assert.deepEqual(validateSeedEnvironment(validSeed), {
    email: 'first.admin@example.com',
    password: 'StrongPassword1!',
    fullName: 'First Admin',
    phone: '+923001234567',
  });

  assert.throws(() => validateSeedEnvironment({ ...validSeed, ADMIN_SEED_EMAIL: 'bad' }), /EMAIL/);
  assert.throws(() => validateSeedEnvironment({ ...validSeed, ADMIN_SEED_PASSWORD: 'weak' }), /PASSWORD/);
  assert.throws(() => validateSeedEnvironment({ ...validSeed, ADMIN_SEED_FULL_NAME: ' ' }), /FULL_NAME/);
  assert.throws(() => validateSeedEnvironment({ ...validSeed, ADMIN_SEED_PHONE: '03001234567' }), /PHONE/);
});

test('Supabase configuration is loaded from an env file without exposing values', () => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'mediconnect-admin-'));
  const envPath = path.join(tempDir, '.env.local');
  fs.writeFileSync(
    envPath,
    'NEXT_PUBLIC_SUPABASE_URL="https://project.supabase.co"\nSUPABASE_SERVICE_ROLE_KEY=private-key\n',
  );

  assert.deepEqual(loadSupabaseConfiguration(envPath), {
    supabaseUrl: 'https://project.supabase.co',
    serviceRoleKey: 'private-key',
  });
});

test('bootstrap creates a confirmed user, upserts an active admin, and verifies it', async () => {
  const calls = [];
  const client = createMockClient({ calls });
  const user = await bootstrapAdmin(client, normalizedSeed());

  assert.equal(user.id, '12345678-1234-1234-1234-123456789abc');
  assert.equal(calls[0].operation, 'listUsers');
  assert.deepEqual(calls[1], {
    operation: 'createUser',
    attributes: {
      email: 'first.admin@example.com',
      password: 'StrongPassword1!',
      email_confirm: true,
      user_metadata: { full_name: 'First Admin', phone: '+923001234567' },
    },
  });
  assert.equal(calls[2].operation, 'upsert');
  assert.equal(calls[2].profile.role, 'admin');
  assert.equal(calls[2].profile.is_active, true);
  assert.equal(calls.at(-1).operation, 'single');
});

test('bootstrap reuses the exact email and updates that Auth user idempotently', async () => {
  const calls = [];
  const existingUser = {
    id: '12345678-1234-1234-1234-123456789abc',
    email: 'FIRST.ADMIN@example.com',
  };
  const client = createMockClient({
    calls,
    users: [existingUser],
    existingProfile: { role: 'admin', is_active: true },
  });
  await bootstrapAdmin(client, normalizedSeed());

  assert.equal(calls.some((call) => call.operation === 'createUser'), false);
  assert.deepEqual(calls.find((call) => call.operation === 'updateUserById'), {
    operation: 'updateUserById',
    userId: existingUser.id,
    attributes: {
      password: 'StrongPassword1!',
      email_confirm: true,
      user_metadata: { full_name: 'First Admin', phone: '+923001234567' },
    },
  });
});

test('bootstrap refuses to promote or reset an existing non-admin account', async () => {
  const calls = [];
  const existingUser = {
    id: '12345678-1234-1234-1234-123456789abc',
    email: 'first.admin@example.com',
  };
  const client = createMockClient({
    calls,
    users: [existingUser],
    existingProfile: { role: 'patient', is_active: true },
  });

  await assert.rejects(
    () => bootstrapAdmin(client, normalizedSeed()),
    /cannot be reused/,
  );
  assert.equal(calls.some((call) => call.operation === 'updateUserById'), false);
  assert.equal(calls.some((call) => call.operation === 'upsert'), false);
});

test('bootstrap refuses to reactivate an existing inactive admin', async () => {
  const existingUser = {
    id: '12345678-1234-1234-1234-123456789abc',
    email: 'first.admin@example.com',
  };
  const client = createMockClient({
    users: [existingUser],
    existingProfile: { role: 'admin', is_active: false },
  });

  await assert.rejects(
    () => bootstrapAdmin(client, normalizedSeed()),
    /cannot be reused/,
  );
});

test('bootstrap fails closed when the stored profile is not an active admin', async () => {
  const client = createMockClient({
    storedProfile: {
      id: '12345678-1234-1234-1234-123456789abc',
      email: 'first.admin@example.com',
      role: 'patient',
      is_active: true,
    },
  });
  await assert.rejects(() => bootstrapAdmin(client, normalizedSeed()), /verification failed/);
});

test('success identifiers are masked', () => {
  assert.equal(maskEmail('first.admin@example.com'), 'fi******@example.com');
  assert.equal(maskUserId('12345678-1234-1234-1234-123456789abc'), '1234...9abc');
});

test('bootstrap entry point stays manual and does not log credential values', () => {
  const source = fs.readFileSync(path.join(__dirname, 'bootstrap-admin.cjs'), 'utf8');
  const packageJson = JSON.parse(
    fs.readFileSync(path.join(__dirname, '..', 'package.json'), 'utf8'),
  );

  assert.equal(packageJson.scripts['bootstrap:admin'], 'node scripts/bootstrap-admin.cjs');
  assert.match(source, /if \(require\.main === module\)/);
  assert.match(source, /email_confirm: true/);
  assert.match(source, /role: 'admin'/);
  assert.match(source, /is_active: true/);
  assert.match(source, /cannot be reused/);
  assert.doesNotMatch(source, /console\.log\([^)]*(password|serviceRoleKey|process\.env)/i);
  assert.doesNotMatch(source, /ADMIN_AUTH_MODE\s*=/);
});

function normalizedSeed() {
  return validateSeedEnvironment(validSeed);
}

function createMockClient({
  calls = [],
  users = [],
  existingProfile,
  storedProfile,
} = {}) {
  const user = { id: '12345678-1234-1234-1234-123456789abc', email: 'first.admin@example.com' };
  const verifiedProfile = storedProfile ?? {
    id: user.id,
    email: user.email,
    role: 'admin',
    is_active: true,
  };

  return {
    auth: {
      admin: {
        async listUsers(options) {
          calls.push({ operation: 'listUsers', options });
          return { data: { users }, error: null };
        },
        async createUser(attributes) {
          calls.push({ operation: 'createUser', attributes });
          return { data: { user }, error: null };
        },
        async updateUserById(userId, attributes) {
          calls.push({ operation: 'updateUserById', userId, attributes });
          return { data: { user }, error: null };
        },
      },
    },
    from(table) {
      assert.equal(table, 'profiles');
      return {
        async upsert(profile, options) {
          calls.push({ operation: 'upsert', profile, options });
          return { error: null };
        },
        select(columns) {
          calls.push({ operation: 'select', columns });
          return {
            eq(column, value) {
              calls.push({ operation: 'eq', column, value });
              return {
                async maybeSingle() {
                  calls.push({ operation: 'maybeSingle' });
                  return { data: existingProfile ?? null, error: null };
                },
                async single() {
                  calls.push({ operation: 'single' });
                  return { data: verifiedProfile, error: null };
                },
              };
            },
          };
        },
      };
    },
  };
}
