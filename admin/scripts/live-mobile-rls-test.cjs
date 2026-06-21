const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

function readEnv() {
  return Object.fromEntries(
    fs
      .readFileSync('.env.local', 'utf8')
      .split(/\r?\n/)
      .filter(Boolean)
      .map((line) => {
        const index = line.indexOf('=');
        return [line.slice(0, index), line.slice(index + 1)];
      }),
  );
}

function client(url, key) {
  return createClient(url, key, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

async function ok(label, result) {
  if (result.error) {
    throw new Error(`${label}: ${result.error.message}`);
  }
  return result.data;
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

async function createUserAndSignIn(supabase, admin, { email, password, fullName, phone, role }) {
  const response = await ok(
    `admin create confirmed demo user ${email}`,
    await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      data: {
        full_name: fullName,
        phone,
        role,
      },
    }),
  );

  await ok(
    `mobile sign-in ${email}`,
    await supabase.auth.signInWithPassword({
      email,
      password,
    }),
  );

  return response.user;
}

async function main() {
  const env = readEnv();
  assert(env.NEXT_PUBLIC_SUPABASE_URL, 'Missing NEXT_PUBLIC_SUPABASE_URL');
  assert(env.NEXT_PUBLIC_SUPABASE_ANON_KEY, 'Missing NEXT_PUBLIC_SUPABASE_ANON_KEY');
  assert(env.SUPABASE_SERVICE_ROLE_KEY, 'Missing SUPABASE_SERVICE_ROLE_KEY');
  assert(process.env.LIVE_TEST_PASSWORD, 'Missing process-only LIVE_TEST_PASSWORD');

  const admin = client(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);
  const patientClient = client(env.NEXT_PUBLIC_SUPABASE_URL, env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
  const workerClient = client(env.NEXT_PUBLIC_SUPABASE_URL, env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
  const stamp = Date.now();
  const password = process.env.LIVE_TEST_PASSWORD;
  const workerEmail = `worker.demo.mobile.${stamp}@gmail.com`;
  const patientEmail = `patient.demo.mobile.${stamp}@gmail.com`;

  const workerUser = await createUserAndSignIn(workerClient, admin, {
    email: workerEmail,
    password,
    fullName: `Mobile Demo Nurse ${stamp}`,
    phone: '+92 300 4444444',
    role: 'health_worker',
  });

  await ok(
    'worker creates own profile',
    await workerClient.from('profiles').upsert({
      id: workerUser.id,
      role: 'health_worker',
      full_name: `Mobile Demo Nurse ${stamp}`,
      phone: '+92 300 4444444',
      email: workerEmail,
      preferred_language: 'en',
    }),
  );

  const category = await ok(
    'worker reads service category',
    await workerClient
      .from('service_categories')
      .select('id,name_en')
      .eq('name_en', 'Injection')
      .single(),
  );

  const worker = await ok(
    'worker creates health worker record',
    await workerClient
      .from('health_workers')
      .insert({
        user_id: workerUser.id,
        worker_type: 'nurse',
        qualification: 'Registered Nurse',
        experience_years: 3,
        city: 'Karachi',
        service_area: 'PECHS',
        bio: 'Mobile RLS test worker.',
      })
      .select('id,verification_status')
      .single(),
  );
  assert(worker.verification_status === 'pending', 'Worker should begin pending');

  await ok(
    'worker uploads own document records',
    await workerClient.from('worker_documents').insert([
      {
        worker_id: worker.id,
        document_type: 'cnic',
        file_path: `demo/mobile/${stamp}/cnic`,
      },
      {
        worker_id: worker.id,
        document_type: 'certificate',
        file_path: `demo/mobile/${stamp}/certificate`,
      },
    ]),
  );

  await ok(
    'worker creates own wallet',
    await workerClient.from('wallets').insert({
      worker_id: worker.id,
      balance_pkr: 2000,
    }),
  );

  await ok(
    'worker creates service pricing',
    await workerClient.from('worker_services').insert({
      worker_id: worker.id,
      service_category_id: category.id,
      base_price_pkr: 1100,
      is_active: true,
    }),
  );

  await ok(
    'admin approves worker',
    await admin
      .from('health_workers')
      .update({
        verification_status: 'approved',
        is_available: true,
        rejection_reason: null,
      })
      .eq('id', worker.id),
  );

  const patientUser = await createUserAndSignIn(patientClient, admin, {
    email: patientEmail,
    password,
    fullName: `Mobile Demo Patient ${stamp}`,
    phone: '+92 300 5555555',
    role: 'patient',
  });

  await ok(
    'patient creates own profile',
    await patientClient.from('profiles').upsert({
      id: patientUser.id,
      role: 'patient',
      full_name: `Mobile Demo Patient ${stamp}`,
      phone: '+92 300 5555555',
      email: patientEmail,
      preferred_language: 'en',
    }),
  );

  const patient = await ok(
    'patient creates patient record',
    await patientClient
      .from('patients')
      .insert({
        user_id: patientUser.id,
        gender: 'male',
        address: 'Mobile Demo House',
        city: 'Karachi',
        emergency_contact_phone: '+92 300 6666666',
        medical_notes: 'Mobile RLS test patient.',
      })
      .select('id')
      .single(),
  );

  const location = await ok(
    'patient creates location',
    await patientClient
      .from('locations')
      .insert({
        user_id: patientUser.id,
        label: 'service request',
        address: 'Mobile Demo House',
        city: 'Karachi',
        is_default: false,
      })
      .select('id')
      .single(),
  );

  const visibleWorkers = await ok(
    'patient reads approved available worker service',
    await patientClient
      .from('worker_services')
      .select(
        'base_price_pkr, health_workers!inner(id, verification_status, is_available)',
      )
      .eq('service_category_id', category.id)
      .eq('health_workers.verification_status', 'approved')
      .eq('health_workers.is_available', true),
  );
  assert(
    visibleWorkers.some((row) => row.health_workers.id === worker.id),
    'Patient should see the approved available worker',
  );

  const request = await ok(
    'patient creates service request',
    await patientClient
      .from('service_requests')
      .insert({
        patient_id: patient.id,
        service_category_id: category.id,
        description: 'Mobile RLS injection request.',
        location_id: location.id,
        status: 'searching',
      })
      .select('id')
      .single(),
  );

  const offer = await ok(
    'patient sends offer to worker',
    await patientClient
      .from('service_request_offers')
      .insert({
        service_request_id: request.id,
        patient_id: patient.id,
        worker_id: worker.id,
        quoted_price_pkr: 1100,
        status: 'pending',
      })
      .select('id,status')
      .single(),
  );

  const workerOffers = await ok(
    'worker reads incoming offer',
    await workerClient
      .from('service_request_offers')
      .select('id,status')
      .eq('worker_id', worker.id)
      .eq('status', 'pending'),
  );
  assert(workerOffers.some((row) => row.id === offer.id), 'Worker should see incoming offer');

  await ok(
    'worker accepts offer',
    await workerClient
      .from('service_request_offers')
      .update({
        status: 'accepted',
        responded_at: new Date().toISOString(),
      })
      .eq('id', offer.id),
  );

  const order = await ok(
    'worker creates accepted order',
    await workerClient
      .from('orders')
      .insert({
        service_request_id: request.id,
        patient_id: patient.id,
        worker_id: worker.id,
        service_category_id: category.id,
        quoted_price_pkr: 1100,
        status: 'accepted',
        accepted_at: new Date().toISOString(),
      })
      .select('id,status')
      .single(),
  );

  const chat = await ok(
    'worker creates chat',
    await workerClient
      .from('chats')
      .insert({
        order_id: order.id,
        patient_user_id: patientUser.id,
        worker_user_id: workerUser.id,
      })
      .select('id')
      .single(),
  );

  await ok(
    'patient sends chat message',
    await patientClient.from('messages').insert({
      chat_id: chat.id,
      sender_user_id: patientUser.id,
      message_type: 'text',
      body: 'Patient mobile RLS message.',
    }),
  );

  await ok(
    'worker sends chat message',
    await workerClient.from('messages').insert({
      chat_id: chat.id,
      sender_user_id: workerUser.id,
      message_type: 'text',
      body: 'Worker mobile RLS reply.',
    }),
  );

  await ok(
    'worker marks order on way through RPC',
    await workerClient.rpc('update_order_status_with_event', {
      target_order_id: order.id,
      target_status: 'worker_on_way',
      event_metadata: { source: 'live-mobile-rls-test' },
    }),
  );

  await ok(
    'worker starts order through RPC',
    await workerClient.rpc('update_order_status_with_event', {
      target_order_id: order.id,
      target_status: 'started',
      event_metadata: { source: 'live-mobile-rls-test' },
    }),
  );

  await ok(
    'worker completes order through RPC',
    await workerClient.rpc('complete_order_with_commission', {
      target_order_id: order.id,
      final_price: 1100,
    }),
  );

  const review = await ok(
    'patient submits review',
    await patientClient
      .from('reviews')
      .insert({
        order_id: order.id,
        patient_id: patient.id,
        worker_id: worker.id,
        rating: 5,
        review_text: 'Mobile RLS review.',
      })
      .select('id,rating')
      .single(),
  );
  assert(review.rating === 5, 'Review rating should be 5');

  const dispute = await ok(
    'patient reports dispute',
    await patientClient
      .from('disputes')
      .insert({
        order_id: order.id,
        reported_by: patientUser.id,
        reason: 'Mobile RLS dispute',
        details: 'Demo dispute created during automated testing.',
        status: 'open',
      })
      .select('id,status')
      .single(),
  );
  assert(dispute.status === 'open', 'Dispute should be open');

  const walletAfter = await ok(
    'admin reads final wallet',
    await admin
      .from('wallets')
      .select('id,balance_pkr')
      .eq('worker_id', worker.id)
      .single(),
  );
  assert(walletAfter.balance_pkr === 1890, `Expected wallet 1890, got ${walletAfter.balance_pkr}`);

  const topUp = await ok(
    'worker requests wallet top-up',
    await workerClient
      .from('wallet_transactions')
      .insert({
        wallet_id: walletAfter.id,
        type: 'top_up',
        amount_pkr: 1000,
        direction: 'credit',
        status: 'pending',
        reference: 'EasyPaisa: MOBILE-RLS-DEMO',
      })
      .select('id,status')
      .single(),
  );
  assert(topUp.status === 'pending', 'Top-up should be pending');

  console.log(
    JSON.stringify(
      {
        passed: true,
        scope: 'Mobile-client RLS flow using anon key plus admin-only approval/read steps',
        cleanup: 'Covered by supabase/cleanup_test_data_before_launch.sql',
        testAccounts: {
          workerEmail,
          patientEmail,
        },
        ids: {
          workerId: worker.id,
          patientId: patient.id,
          requestId: request.id,
          offerId: offer.id,
          orderId: order.id,
          chatId: chat.id,
          reviewId: review.id,
          disputeId: dispute.id,
          topUpId: topUp.id,
        },
        finalState: {
          orderStatus: 'completed',
          expectedWalletBalancePkr: 1890,
          pendingTopUpPkr: 1000,
        },
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
