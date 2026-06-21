const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const ts = require('typescript');
const { webcrypto } = require('node:crypto');

function loadAdminAccessModule() {
  return loadTypeScriptModule(path.join(__dirname, '..', 'lib', 'admin-access.ts'));
}

function loadAdminWalletReviewModule() {
  return loadTypeScriptModule(path.join(__dirname, '..', 'lib', 'admin-wallet-review.ts'));
}

function loadAdminDisputeReviewModule() {
  return loadTypeScriptModule(path.join(__dirname, '..', 'lib', 'admin-dispute-review.ts'));
}

function loadAdminServiceStatusModule() {
  return loadTypeScriptModule(path.join(__dirname, '..', 'lib', 'admin-service-status.ts'));
}

function loadAdminAuditMetadataModule() {
  return loadTypeScriptModule(path.join(__dirname, '..', 'lib', 'admin-audit-metadata.ts'));
}

function loadAdminWorkerVerificationModule() {
  return loadTypeScriptModule(path.join(__dirname, '..', 'lib', 'admin-worker-verification.ts'));
}

function loadDeploymentHealthModule() {
  return loadTypeScriptModule(path.join(__dirname, '..', 'lib', 'deployment-health.ts'));
}

function loadTypeScriptModule(sourcePath) {
  const source = fs.readFileSync(sourcePath, 'utf8');
  const { outputText } = ts.transpileModule(source, {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2022,
    },
  });

  const loadedModule = { exports: {} };
  const run = new Function('exports', 'module', 'require', 'process', 'crypto', outputText);
  run(loadedModule.exports, loadedModule, require, process, webcrypto);
  return loadedModule.exports;
}

const originalEnv = { ...process.env };

function resetEnv() {
  process.env.ADMIN_AUTH_MODE = originalEnv.ADMIN_AUTH_MODE;
  process.env.ADMIN_SESSION_SECRET = originalEnv.ADMIN_SESSION_SECRET;
  process.env.SUPABASE_SERVICE_ROLE_KEY = originalEnv.SUPABASE_SERVICE_ROLE_KEY;
  process.env.NEXT_PUBLIC_SUPABASE_URL = originalEnv.NEXT_PUBLIC_SUPABASE_URL;
}

function readAdminDataSource() {
  return fs.readFileSync(path.join(__dirname, '..', 'lib', 'admin-data.ts'), 'utf8');
}

function readScriptSource(scriptName) {
  return fs.readFileSync(path.join(__dirname, scriptName), 'utf8');
}

function readProjectDoc(docName) {
  return fs.readFileSync(path.join(__dirname, '..', '..', 'docs', docName), 'utf8');
}

function getExportedFunctionSource(source, functionName) {
  const start = source.indexOf(`export async function ${functionName}`);
  assert.notEqual(start, -1, `${functionName} should exist`);

  const nextExport = source.indexOf('export async function ', start + 1);
  return source.slice(start, nextExport === -1 ? undefined : nextExport);
}

function getAdminAuditCallSources(source) {
  return source.match(/insertAdminAuditLog\(supabase, \{[\s\S]*?\n  \}\);/g) ?? [];
}

test.afterEach(resetEnv);

test('admin auth mode defaults to access-code mode', () => {
  const access = loadAdminAccessModule();

  delete process.env.ADMIN_AUTH_MODE;
  assert.equal(access.getAdminAuthMode(), 'access_code');

  process.env.ADMIN_AUTH_MODE = 'supabase_role';
  assert.equal(access.getAdminAuthMode(), 'supabase_role');
});

test('access-code tokens validate only against the configured code', async () => {
  const access = loadAdminAccessModule();
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-secret';
  process.env.NEXT_PUBLIC_SUPABASE_URL = 'https://example.supabase.co';

  const token = await access.createAdminAccessToken('correct-code');

  assert.equal(await access.isValidAdminAccessToken(token, 'correct-code'), true);
  assert.equal(await access.isValidAdminAccessToken(token, 'wrong-code'), false);
  assert.equal(await access.isValidAdminAccessToken(undefined, 'correct-code'), false);
});

test('admin-role cookies fail closed without ADMIN_SESSION_SECRET', async () => {
  const access = loadAdminAccessModule();
  delete process.env.ADMIN_SESSION_SECRET;
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-secret';
  process.env.NEXT_PUBLIC_SUPABASE_URL = 'https://example.supabase.co';

  await assert.rejects(
    () => access.createAdminRoleCookieValue('admin-user-id'),
    /ADMIN_SESSION_SECRET/,
  );
  assert.equal(await access.isValidAdminRoleCookieValue('admin-user-id.token'), false);
});

test('admin-role cookies validate with ADMIN_SESSION_SECRET', async () => {
  const access = loadAdminAccessModule();
  process.env.ADMIN_SESSION_SECRET = 'session-secret';
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-secret';
  process.env.NEXT_PUBLIC_SUPABASE_URL = 'https://example.supabase.co';

  const cookieValue = await access.createAdminRoleCookieValue('admin-user-id');

  assert.equal(await access.isValidAdminRoleCookieValue(cookieValue), true);
  assert.equal(await access.isValidAdminRoleCookieValue(`${cookieValue}tampered`), false);
  assert.equal(await access.isValidAdminRoleCookieValue('bad-cookie'), false);
});

test('deployment health fails closed when required configuration is missing', () => {
  const health = loadDeploymentHealthModule();
  const configured = {
    NEXT_PUBLIC_SUPABASE_URL: 'https://example.supabase.co',
    NEXT_PUBLIC_SUPABASE_ANON_KEY: 'anon-key',
    SUPABASE_SERVICE_ROLE_KEY: 'service-key',
  };

  assert.equal(health.deploymentHealthStatus(configured), 'ok');
  assert.equal(
    health.deploymentHealthStatus({
      ...configured,
      ADMIN_AUTH_MODE: 'supabase_role',
    }),
    'misconfigured',
  );
  assert.equal(
    health.deploymentHealthStatus({
      ...configured,
      ADMIN_AUTH_MODE: 'supabase_role',
      ADMIN_SESSION_SECRET: 'session-secret',
    }),
    'ok',
  );
  assert.equal(
    health.deploymentHealthStatus({
      ...configured,
      SUPABASE_SERVICE_ROLE_KEY: '',
    }),
    'misconfigured',
  );
});

test('public health route stays minimal and bypasses admin login redirect', () => {
  const routeSource = fs.readFileSync(
    path.join(__dirname, '..', 'app', 'api', 'health', 'route.ts'),
    'utf8',
  );
  const middlewareSource = fs.readFileSync(
    path.join(__dirname, '..', 'middleware.ts'),
    'utf8',
  );

  assert.match(routeSource, /deploymentHealthStatus\(process\.env\)/);
  assert.match(routeSource, /status === 'ok' \? 200 : 503/);
  assert.match(routeSource, /Cache-Control/);
  assert.doesNotMatch(routeSource, /SUPABASE_SERVICE_ROLE_KEY|ADMIN_SESSION_SECRET/);
  assert.doesNotMatch(routeSource, /missing|database|error/i);
  assert.match(middlewareSource, /path === '\/api\/health'/);
});

test('production responses use the documented browser security headers', () => {
  const nextConfigSource = fs.readFileSync(
    path.join(__dirname, '..', 'next.config.mjs'),
    'utf8',
  );

  for (const requiredHeader of [
    'Cross-Origin-Opener-Policy',
    'Permissions-Policy',
    'Referrer-Policy',
    'Strict-Transport-Security',
    'X-Content-Type-Options',
    'X-Frame-Options',
  ]) {
    assert.match(nextConfigSource, new RegExp(requiredHeader));
  }

  assert.match(nextConfigSource, /poweredByHeader:\s*false/);
  assert.match(nextConfigSource, /source:\s*'\/:path\*'/);
});

test('wallet top-up review form trims ids and applies requested decision', () => {
  const walletReview = loadAdminWalletReviewModule();
  const formData = new FormData();
  formData.set('transactionId', ' transaction-id ');
  formData.set('walletId', ' client-submitted-wallet-id ');

  assert.deepEqual(walletReview.parseWalletTopUpReviewForm(formData, true), {
    transactionId: 'transaction-id',
    approved: true,
  });

  assert.deepEqual(walletReview.parseWalletTopUpReviewForm(formData, false), {
    transactionId: 'transaction-id',
    approved: false,
  });
});

test('wallet top-up review form requires transaction id only', () => {
  const walletReview = loadAdminWalletReviewModule();
  const missingTransaction = new FormData();

  assert.throws(
    () => walletReview.parseWalletTopUpReviewForm(missingTransaction, true),
    /Missing wallet top-up transaction/,
  );

  const formData = new FormData();
  formData.set('transactionId', 'transaction-id');

  assert.deepEqual(walletReview.parseWalletTopUpReviewForm(formData, false), {
    transactionId: 'transaction-id',
    approved: false,
  });
});

test('admin wallet review uses the atomic Supabase RPC only', () => {
  const adminDataSource = readAdminDataSource();
  const reviewFunctionSource = getExportedFunctionSource(
    adminDataSource,
    'reviewWalletTopUp',
  );

  assert.match(reviewFunctionSource, /\.rpc\('review_wallet_top_up'/);
  assert.doesNotMatch(reviewFunctionSource, /\.from\('wallets'\)/);
  assert.doesNotMatch(reviewFunctionSource, /\.from\('wallet_transactions'\)/);
  assert.doesNotMatch(reviewFunctionSource, /amount_pkr/);
  assert.doesNotMatch(reviewFunctionSource, /walletId/);
});

test('privileged admin data functions write audit logs', () => {
  const adminDataSource = readAdminDataSource();
  const auditedFunctions = [
    'updateWorkerVerification',
    'reviewWalletTopUp',
    'updateDisputeStatus',
    'updateServiceCategoryStatus',
  ];

  for (const functionName of auditedFunctions) {
    const functionSource = getExportedFunctionSource(adminDataSource, functionName);
    assert.match(
      functionSource,
      /insertAdminAuditLog\(supabase, \{/,
      `${functionName} should insert an admin audit log`,
    );
  }

  assert.equal(getAdminAuditCallSources(adminDataSource).length, auditedFunctions.length);
});

test('admin audit metadata excludes secrets and free-text review details', () => {
  const adminDataSource = readAdminDataSource();
  const auditCalls = getAdminAuditCallSources(adminDataSource).join('\n');

  assert.match(auditCalls, /worker_id/);
  assert.match(auditCalls, /has_rejection_reason/);
  assert.match(auditCalls, /transaction_id/);
  assert.match(auditCalls, /dispute_id/);
  assert.match(auditCalls, /has_resolution_notes/);
  assert.match(auditCalls, /category_id/);

  assert.doesNotMatch(
    auditCalls,
    /SERVICE_ROLE|ADMIN_ACCESS|ADMIN_SESSION|accessCode|password|reference|screenshot|signedUrl|walletId|amount_pkr|resolutionNotes|rejectionReason/i,
  );
});

test('admin audit metadata sanitizer keeps compact operational fields only', () => {
  const auditMetadata = loadAdminAuditMetadataModule();

  assert.deepEqual(
    auditMetadata.sanitizeAuditMetadata({
      worker_id: 'worker-123',
      status: 'approved',
      approved: true,
      total_count: 3,
      reference: 'JazzCash sender reference',
      screenshot_path: 'wallet-topups/demo.png',
      signedUrl: 'https://example.com/signed',
      access_code: 'secret-code',
      service_role_key: 'service-role-secret',
      resolution_notes: 'Free-text dispute notes.',
      rejectionReason: 'Free-text worker decision notes.',
      description: 'Patient request details.',
      amount_pkr: 5000,
      nested: { status: 'approved' },
    }),
    [
      { label: 'Worker Id', value: 'worker-123' },
      { label: 'Status', value: 'approved' },
      { label: 'Approved', value: 'Yes' },
      { label: 'Total Count', value: '3' },
    ],
  );
});

test('admin audit logs page uses the sanitized unified timeline', () => {
  const pageSource = fs.readFileSync(
    path.join(__dirname, '..', 'app', 'audit-logs', 'page.tsx'),
    'utf8',
  );

  assert.match(pageSource, /getAdminAuditTimeline/);
  assert.match(pageSource, /Admin action/);
  assert.match(pageSource, /Order event/);
  assert.doesNotMatch(pageSource, /JSON\.stringify\(event\.metadata/);
  assert.doesNotMatch(pageSource, /<pre/);
});

test('admin order detail timeline renders sanitized metadata chips only', () => {
  const pageSource = fs.readFileSync(
    path.join(__dirname, '..', 'app', 'orders', '[id]', 'page.tsx'),
    'utf8',
  );

  assert.match(pageSource, /sanitizeAuditMetadata/);
  assert.match(pageSource, /sanitizeAuditMetadata\(event\.metadata\)/);
  assert.match(pageSource, /SafeMetadataChips/);
  assert.match(pageSource, /No safe metadata to display/);
  assert.doesNotMatch(pageSource, /JSON\.stringify\(event\.metadata/);
  assert.doesNotMatch(pageSource, /JSON\.stringify\(metadata/);
  assert.doesNotMatch(pageSource, /<pre/);
});

test('admin pages use shared empty and metric UI helpers for polish consistency', () => {
  const sharedUiSource = fs.readFileSync(
    path.join(__dirname, '..', 'app', 'components', 'admin-ui.tsx'),
    'utf8',
  );
  const pagesUsingEmptyState = [
    path.join('workers', 'page.tsx'),
    path.join('patients', 'page.tsx'),
    path.join('orders', 'page.tsx'),
    path.join('wallets', 'page.tsx'),
    path.join('services', 'page.tsx'),
    path.join('reviews', 'page.tsx'),
    path.join('disputes', 'page.tsx'),
    path.join('audit-logs', 'page.tsx'),
  ];

  assert.match(sharedUiSource, /export function EmptyState/);
  assert.match(sharedUiSource, /export function MetricCard/);
  assert.match(sharedUiSource, /max-w-md text-sm text-slate-600/);

  for (const pagePath of pagesUsingEmptyState) {
    const pageSource = fs.readFileSync(
      path.join(__dirname, '..', 'app', pagePath),
      'utf8',
    );
    assert.match(pageSource, /EmptyState/, `${pagePath} should use EmptyState`);
  }
});

test('settings page does not reveal partial secret values', () => {
  const settingsSource = fs.readFileSync(
    path.join(__dirname, '..', 'app', 'settings', 'page.tsx'),
    'utf8',
  );
  const displayValueSource = settingsSource.slice(
    settingsSource.indexOf('function displayValue'),
  );

  assert.match(displayValueSource, /return 'Configured';/);
  assert.doesNotMatch(displayValueSource, /slice\(0/);
  assert.doesNotMatch(displayValueSource, /slice\(-/);
});

test('settings and live setup docs list required backend migrations', () => {
  const settingsSource = fs.readFileSync(
    path.join(__dirname, '..', 'app', 'settings', 'page.tsx'),
    'utf8',
  );
  const liveSetupDoc = readProjectDoc('07-live-supabase-setup.md');
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

  for (const migration of requiredMigrations) {
    assert.match(settingsSource, new RegExp(migration));
    assert.match(liveSetupDoc, new RegExp(migration));
  }

  assert.match(settingsSource, /review_wallet_top_up RPC required/);
  assert.match(settingsSource, /update_order_status_with_event RPC required/);
  assert.match(settingsSource, /audit_logs table required/);
  assert.match(settingsSource, /find_available_workers_for_request RPC required/);
  assert.match(liveSetupDoc, /update_order_status_with_event/);
  assert.match(liveSetupDoc, /audit_logs/);
  assert.match(liveSetupDoc, /find_available_workers_for_request/);
});

test('worker distance matching RPC is patient-only and hides discovery phone data', () => {
  const migrationSource = fs.readFileSync(
    path.join(
      __dirname,
      '..',
      '..',
      'supabase',
      'migrations',
      '20260617110000_worker_distance_matching.sql',
    ),
    'utf8',
  );

  assert.match(migrationSource, /create or replace function public\.find_available_workers_for_request/);
  assert.match(migrationSource, /current_profile\.role = 'patient'/);
  assert.match(migrationSource, /current_profile\.is_active = true/);
  assert.match(migrationSource, /null::text as phone/);
  assert.match(migrationSource, /current_location_updated_at >= now\(\) - interval '8 hours'/);
  assert.match(migrationSource, /matched_workers\.distance_km <= max_distance_km/);
});

test('readiness preflight covers launch blockers without printing secrets', () => {
  const readinessSource = readScriptSource('readiness-check.cjs');
  const packageJson = JSON.parse(
    fs.readFileSync(path.join(__dirname, '..', 'package.json'), 'utf8'),
  );

  assert.equal(packageJson.scripts['test:readiness'], 'node scripts/readiness-check.cjs');
  assert.equal(
    packageJson.scripts['test:quality'],
    'npm run test:readiness && npm run test:unit && npm run lint && npm run build',
  );

  for (const requiredText of [
    'requiredDocs',
    'requiredMigrations',
    'cleanup_test_data_before_launch.sql',
    '.env.local.example',
    '.vercelignore',
    'Vercel upload excludes secrets and local operator scripts',
    'Environment secret files are ignored by git',
    'NEXT_PUBLIC_SUPABASE_URL',
    'NEXT_PUBLIC_SUPABASE_ANON_KEY',
    'SUPABASE_SERVICE_ROLE_KEY',
    'ADMIN_ACCESS_CODE',
    'ADMIN_SESSION_SECRET',
    'ADMIN_SEED_EMAIL',
    'ADMIN_SEED_PASSWORD',
    'ADMIN_SEED_FULL_NAME',
    'ADMIN_SEED_PHONE',
    'Manual admin bootstrap utility exists',
    'The readiness check never executes this networked utility.',
    'ANDROID_HOME',
    'ANDROID_SDK_ROOT',
    'local fallback checks',
    'com.mediconnect.app',
    'key.properties.example',
    'hasAndroidReleaseSigningConfigured',
    'Android release signing configured',
    'No live Supabase data is read or modified by this check.',
  ]) {
    assert.match(readinessSource, new RegExp(requiredText.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
  }

  assert.doesNotMatch(readinessSource, /console\.log\([^)]*env\[/i);
  assert.doesNotMatch(readinessSource, /console\.log\([^)]*process\.env/i);
});

test('readiness requires only the credential for the selected admin auth mode', () => {
  const readinessSource = readScriptSource('readiness-check.cjs');

  assert.match(
    readinessSource,
    /adminAuthMode !== 'access_code' \|\| hasValue\(adminEnv, 'ADMIN_ACCESS_CODE'\)/,
  );
  assert.match(
    readinessSource,
    /adminAuthMode !== 'supabase_role' \|\| hasValue\(adminEnv, 'ADMIN_SESSION_SECRET'\)/,
  );
  assert.match(readinessSource, /\['access_code', 'supabase_role'\]\.includes\(adminAuthMode\)/);
});

test('admin audit log schema keeps actor nullable and metadata structured', () => {
  const migrationSource = fs.readFileSync(
    path.join(
      __dirname,
      '..',
      '..',
      'supabase',
      'migrations',
      '20260615130000_admin_audit_logs.sql',
    ),
    'utf8',
  );

  assert.match(migrationSource, /create table if not exists public\.audit_logs/);
  assert.match(
    migrationSource,
    /actor_user_id uuid references public\.profiles\(id\) on delete set null/,
  );
  assert.doesNotMatch(migrationSource, /actor_user_id uuid not null/);
  assert.match(migrationSource, /type text not null/);
  assert.match(migrationSource, /action text not null/);
  assert.match(migrationSource, /metadata jsonb not null default '\{\}'::jsonb/);
  assert.match(migrationSource, /alter table public\.audit_logs enable row level security/);
});

test('wallet top-up review RPC locks and credits the stored transaction amount once', () => {
  const migrationSource = fs.readFileSync(
    path.join(
      __dirname,
      '..',
      '..',
      'supabase',
      'migrations',
      '20260615120000_wallet_top_up_review_rpc.sql',
    ),
    'utf8',
  );

  assert.match(migrationSource, /create or replace function public\.review_wallet_top_up/);
  assert.match(migrationSource, /for update/);
  assert.match(migrationSource, /and status = 'pending'/);
  assert.match(migrationSource, /balance_pkr = balance_pkr \+ top_up_record\.amount_pkr/);
  assert.match(migrationSource, /grant execute on function public\.review_wallet_top_up\(uuid, boolean\) to service_role/);
  assert.match(migrationSource, /revoke execute on function public\.review_wallet_top_up\(uuid, boolean\) from authenticated/);
});

test('live helpers use atomic order status RPCs for non-completion transitions', () => {
  const liveE2eSource = readScriptSource('live-e2e-test.cjs');
  const mobileRlsSource = readScriptSource('live-mobile-rls-test.cjs');

  for (const [scriptName, source] of [
    ['live-e2e-test.cjs', liveE2eSource],
    ['live-mobile-rls-test.cjs', mobileRlsSource],
  ]) {
    assert.match(
      source,
      /\.rpc\('update_order_status_with_event'/,
      `${scriptName} should call update_order_status_with_event`,
    );
    assert.match(source, /target_status:\s*'worker_on_way'/);
    assert.match(source, /target_status:\s*'started'/);
    assert.doesNotMatch(
      source,
      /\.from\('orders'\)[\s\S]{0,180}\.update\(\{\s*status:\s*'worker_on_way'/,
      `${scriptName} should not directly mark worker_on_way`,
    );
    assert.doesNotMatch(
      source,
      /\.from\('orders'\)[\s\S]{0,180}\.update\(\{\s*status:\s*'started'/,
      `${scriptName} should not directly mark started`,
    );
    assert.doesNotMatch(
      source,
      /event_type:\s*'worker_on_way'|event_type:\s*'started'/,
      `${scriptName} should let the status RPC write status order_events`,
    );
  }
});

test('live helpers require process-only credentials and never print passwords', () => {
  const liveE2eSource = readScriptSource('live-e2e-test.cjs');
  const mobileRlsSource = readScriptSource('live-mobile-rls-test.cjs');

  for (const source of [liveE2eSource, mobileRlsSource]) {
    assert.match(source, /process\.env\.LIVE_TEST_PASSWORD/);
    assert.match(source, /Missing process-only LIVE_TEST_PASSWORD/);
    assert.doesNotMatch(source, /Demo123!/);
    assert.doesNotMatch(source, /testCredentials/);
  }
});

test('live e2e helper uses wallet top-up review RPC instead of direct approval mutations', () => {
  const liveE2eSource = readScriptSource('live-e2e-test.cjs');

  assert.match(liveE2eSource, /\.rpc\('review_wallet_top_up'/);
  assert.doesNotMatch(
    liveE2eSource,
    /\.from\('wallet_transactions'\)[\s\S]{0,220}\.update\(/,
  );
  assert.doesNotMatch(liveE2eSource, /reviewed_at:\s*new Date\(\)\.toISOString\(\)/);
  assert.doesNotMatch(liveE2eSource, /\.from\('wallets'\)[\s\S]{0,220}\.update\(/);
  assert.doesNotMatch(liveE2eSource, /balance_pkr:\s*2850/);
});

test('dispute review form trims id and optional notes', () => {
  const disputeReview = loadAdminDisputeReviewModule();
  const formData = new FormData();
  formData.set('disputeId', ' dispute-id ');
  formData.set('resolutionNotes', ' Needs follow-up call. ');

  assert.deepEqual(disputeReview.parseDisputeReviewForm(formData, 'resolved'), {
    disputeId: 'dispute-id',
    status: 'resolved',
    resolutionNotes: 'Needs follow-up call.',
  });
});

test('dispute review form requires id and allowed status', () => {
  const disputeReview = loadAdminDisputeReviewModule();
  const missingDispute = new FormData();

  assert.throws(
    () => disputeReview.parseDisputeReviewForm(missingDispute, 'reviewing'),
    /Missing dispute/,
  );

  assert.throws(
    () =>
      disputeReview.assertValidDisputeReview({
        disputeId: 'dispute-id',
        status: 'open',
      }),
    /Invalid dispute review status/,
  );
});

test('service status form trims category id and parses active flag', () => {
  const serviceStatus = loadAdminServiceStatusModule();
  const activateForm = new FormData();
  activateForm.set('categoryId', ' category-id ');
  activateForm.set('isActive', 'true');

  assert.deepEqual(serviceStatus.parseServiceStatusForm(activateForm), {
    categoryId: 'category-id',
    isActive: true,
  });

  const deactivateForm = new FormData();
  deactivateForm.set('categoryId', 'category-id');
  deactivateForm.set('isActive', 'false');

  assert.deepEqual(serviceStatus.parseServiceStatusForm(deactivateForm), {
    categoryId: 'category-id',
    isActive: false,
  });
});

test('service status form requires category id', () => {
  const serviceStatus = loadAdminServiceStatusModule();
  const formData = new FormData();
  formData.set('isActive', 'true');

  assert.throws(
    () => serviceStatus.parseServiceStatusForm(formData),
    /Missing service category/,
  );
});

test('worker verification form trims worker id and rejection reason', () => {
  const workerVerification = loadAdminWorkerVerificationModule();
  const formData = new FormData();
  formData.set('workerId', ' worker-id ');
  formData.set('rejectionReason', ' Missing qualification file. ');

  assert.deepEqual(workerVerification.parseWorkerVerificationForm(formData, 'rejected'), {
    workerId: 'worker-id',
    status: 'rejected',
    rejectionReason: 'Missing qualification file.',
  });

  assert.deepEqual(workerVerification.parseWorkerVerificationForm(formData, 'approved'), {
    workerId: 'worker-id',
    status: 'approved',
    rejectionReason: undefined,
  });
});

test('worker verification form requires worker id and allowed status', () => {
  const workerVerification = loadAdminWorkerVerificationModule();
  const missingWorker = new FormData();

  assert.throws(
    () => workerVerification.parseWorkerVerificationForm(missingWorker, 'approved'),
    /Missing worker/,
  );

  assert.throws(
    () =>
      workerVerification.assertValidWorkerVerification({
        workerId: 'worker-id',
        status: 'pending',
      }),
    /Invalid worker verification status/,
  );
});

test('worker rejection uses a default reason when admin notes are blank', () => {
  const workerVerification = loadAdminWorkerVerificationModule();
  const formData = new FormData();
  formData.set('workerId', 'worker-id');
  formData.set('rejectionReason', '   ');

  assert.deepEqual(workerVerification.parseWorkerVerificationForm(formData, 'rejected'), {
    workerId: 'worker-id',
    status: 'rejected',
    rejectionReason: 'Documents or profile details need correction.',
  });
});
