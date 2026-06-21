const fs = require('node:fs');
const path = require('node:path');

const repoRoot = path.resolve(__dirname, '..', '..');
const adminRoot = path.join(repoRoot, 'admin');
const mobileRoot = path.join(repoRoot, 'mobile');

const requiredDocs = [
  '01-prd.md',
  '02-trd.md',
  '03-app-flow.md',
  '04-ui-ux-design-brief.md',
  '05-backend-schema.md',
  '06-implementation-plan.md',
  '07-live-supabase-setup.md',
  '08-testing-and-cleanup.md',
];

const requiredMigrations = [
  '20260613140000_initial_schema.sql',
  '20260613170000_service_request_images_bucket.sql',
  '20260613173000_service_request_offers.sql',
  '20260614090000_reviews_and_disputes.sql',
  '20260614103000_chat_image_participant_read.sql',
  '20260615120000_wallet_top_up_review_rpc.sql',
  '20260615123000_order_status_update_rpc.sql',
  '20260615130000_admin_audit_logs.sql',
  '20260617110000_worker_distance_matching.sql',
];

const checks = [];

function fileExists(...parts) {
  return fs.existsSync(path.join(...parts));
}

function readText(...parts) {
  return fs.readFileSync(path.join(...parts), 'utf8');
}

function parseEnvFile(filePath) {
  if (!fs.existsSync(filePath)) {
    return {};
  }

  return Object.fromEntries(
    fs
      .readFileSync(filePath, 'utf8')
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith('#') && line.includes('='))
      .map((line) => {
        const index = line.indexOf('=');
        return [line.slice(0, index), line.slice(index + 1).trim()];
      }),
  );
}

function hasValue(env, key) {
  return Boolean(env[key]?.trim());
}

function hasAndroidSdkConfigured() {
  const sdkPath =
    process.env.ANDROID_HOME ||
    process.env.ANDROID_SDK_ROOT ||
    'C:\\Android\\Sdk';

  return (
    Boolean(sdkPath) &&
    fs.existsSync(path.join(sdkPath, 'platform-tools', 'adb.exe')) &&
    fs.existsSync(path.join(sdkPath, 'cmdline-tools', 'latest', 'bin'))
  );
}

function hasAndroidReleaseSigningConfigured() {
  const androidRoot = path.join(mobileRoot, 'android');
  const propertiesPath = path.join(androidRoot, 'key.properties');
  const properties = parseEnvFile(propertiesPath);
  const requiredKeys = ['storeFile', 'storePassword', 'keyAlias', 'keyPassword'];

  if (
    !requiredKeys.every(
      (key) => hasValue(properties, key) && !properties[key].includes('replace-with-'),
    )
  ) {
    return false;
  }

  return fs.existsSync(path.resolve(androidRoot, properties.storeFile));
}

function record(status, label, detail) {
  checks.push({ status, label, detail });
}

function requireReady(ok, label, detail) {
  record(ok ? 'ready' : 'blocker', label, detail);
}

function manual(ok, label, detail) {
  record(ok ? 'ready' : 'manual', label, detail);
}

function optional(ok, label, detail) {
  record(ok ? 'ready' : 'optional', label, detail);
}

function runChecks() {
  for (const doc of requiredDocs) {
    requireReady(fileExists(repoRoot, 'docs', doc), `Doc exists: ${doc}`);
  }

  for (const migration of requiredMigrations) {
    requireReady(
      fileExists(repoRoot, 'supabase', 'migrations', migration),
      `Migration exists: ${migration}`,
    );
  }

  requireReady(
    fileExists(repoRoot, 'supabase', 'seed.sql'),
    'Service category seed SQL exists',
  );
  requireReady(
    fileExists(repoRoot, 'supabase', 'cleanup_test_data_before_launch.sql'),
    'Final cleanup SQL exists',
  );
  requireReady(
    fileExists(adminRoot, '.env.local.example'),
    'Admin environment example exists',
  );
  const vercelIgnore = readText(adminRoot, '.vercelignore');
  requireReady(
    vercelIgnore.includes('.env.*') &&
      vercelIgnore.includes('scripts/bootstrap-admin.cjs') &&
      vercelIgnore.includes('scripts/live-e2e-test.cjs') &&
      vercelIgnore.includes('scripts/live-mobile-rls-test.cjs'),
    'Vercel upload excludes secrets and local operator scripts',
  );
  requireReady(
    fileExists(adminRoot, 'app', 'api', 'health', 'route.ts'),
    'Admin deployment health endpoint exists',
    'Use /api/health for hosting and uptime monitoring.',
  );
  const adminEnvExample = parseEnvFile(path.join(adminRoot, '.env.local.example'));
  requireReady(
    [
      'ADMIN_SEED_EMAIL',
      'ADMIN_SEED_PASSWORD',
      'ADMIN_SEED_FULL_NAME',
      'ADMIN_SEED_PHONE',
    ].every((key) => Object.hasOwn(adminEnvExample, key)),
    'Manual admin bootstrap placeholders are documented',
    'Real seed values must be supplied through the process environment only.',
  );
  requireReady(
    fileExists(adminRoot, 'scripts', 'bootstrap-admin.cjs'),
    'Manual admin bootstrap utility exists',
    'The readiness check never executes this networked utility.',
  );

  const rootGitignore = readText(repoRoot, '.gitignore');
  requireReady(
    rootGitignore.includes('.env') &&
      rootGitignore.includes('.env.*') &&
      rootGitignore.includes('!.env.local.example'),
    'Environment secret files are ignored by git',
    'Only example env files should be committed.',
  );

  const adminEnv = parseEnvFile(path.join(adminRoot, '.env.local'));
  const adminAuthMode = adminEnv.ADMIN_AUTH_MODE?.trim() || 'access_code';
  requireReady(
    ['access_code', 'supabase_role'].includes(adminAuthMode),
    'Admin auth mode is supported',
    'Use access_code locally or supabase_role for public deployment.',
  );
  requireReady(
    hasValue(adminEnv, 'NEXT_PUBLIC_SUPABASE_URL'),
    'Admin Supabase URL configured',
    'Value is checked for presence only.',
  );
  requireReady(
    hasValue(adminEnv, 'NEXT_PUBLIC_SUPABASE_ANON_KEY'),
    'Admin Supabase anon key configured',
    'Value is checked for presence only.',
  );
  requireReady(
    hasValue(adminEnv, 'SUPABASE_SERVICE_ROLE_KEY'),
    'Admin service role key configured',
    'Value is checked for presence only and must stay server-side.',
  );
  manual(
    adminAuthMode !== 'access_code' || hasValue(adminEnv, 'ADMIN_ACCESS_CODE'),
    'MVP admin access code configured',
    'Required only when ADMIN_AUTH_MODE=access_code.',
  );
  manual(
    adminAuthMode !== 'supabase_role' || hasValue(adminEnv, 'ADMIN_SESSION_SECRET'),
    'Admin session secret configured',
    'Required when ADMIN_AUTH_MODE=supabase_role.',
  );
  optional(
    hasValue(adminEnv, 'NEXT_PUBLIC_MAPS_API_KEY'),
    'Maps API key configured',
    'Only needed when replacing the current location status panel with a real map.',
  );

  const buildGradle = readText(mobileRoot, 'android', 'app', 'build.gradle');
  const manifest = readText(
    mobileRoot,
    'android',
    'app',
    'src',
    'main',
    'AndroidManifest.xml',
  );
  const mobileGitignore = readText(mobileRoot, '.gitignore');

  requireReady(
    buildGradle.includes('applicationId = "com.mediconnect.app"'),
    'Android application id is com.mediconnect.app',
  );
  requireReady(
    buildGradle.includes('signingConfigs') &&
      buildGradle.includes('key.properties') &&
      buildGradle.includes('hasReleaseKeystore'),
    'Android release signing reads local key.properties',
  );
  requireReady(
    manifest.includes('android:label="MediConnect"'),
    'Android launcher label is MediConnect',
  );
  requireReady(
    fileExists(mobileRoot, 'android', 'key.properties.example'),
    'Android key.properties example exists',
  );
  manual(
    hasAndroidReleaseSigningConfigured(),
    'Android release signing configured',
    'Create the upload keystore and local mobile/android/key.properties before an internal release build.',
  );
  requireReady(
    mobileGitignore.includes('/android/key.properties') &&
      mobileGitignore.includes('/android/*.jks') &&
      mobileGitignore.includes('/android/*.keystore'),
    'Android signing secrets are ignored by git',
  );
  manual(
    hasAndroidSdkConfigured(),
    'Android SDK environment configured',
    'Set ANDROID_HOME before building APK/App Bundle; local fallback checks C:\\Android\\Sdk.',
  );

  requireReady(
    fileExists(adminRoot, 'scripts', 'live-e2e-test.cjs') &&
      fileExists(adminRoot, 'scripts', 'live-mobile-rls-test.cjs'),
    'Live test helper scripts exist',
    'Keep until final cleanup is complete.',
  );
}

function printReport() {
  const order = ['blocker', 'manual', 'optional', 'ready'];
  const label = {
    ready: 'READY',
    manual: 'MANUAL',
    optional: 'OPTIONAL',
    blocker: 'BLOCKER',
  };

  console.log('MediConnect local readiness preflight');
  console.log('No live Supabase data is read or modified by this check.\n');

  for (const status of order) {
    const group = checks.filter((check) => check.status === status);
    if (group.length === 0) {
      continue;
    }

    console.log(`${label[status]} (${group.length})`);
    for (const check of group) {
      console.log(`- ${check.label}`);
      if (check.detail) {
        console.log(`  ${check.detail}`);
      }
    }
    console.log('');
  }

  const blockers = checks.filter((check) => check.status === 'blocker');
  if (blockers.length > 0) {
    console.error(`Readiness failed with ${blockers.length} blocker(s).`);
    process.exitCode = 1;
  } else {
    console.log('Readiness preflight completed with no blockers.');
  }
}

runChecks();
printReport();
