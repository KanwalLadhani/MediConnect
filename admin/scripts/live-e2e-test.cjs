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

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

async function requireOk(label, result) {
  if (result.error) {
    throw new Error(`${label}: ${result.error.message}`);
  }
  return result.data;
}

async function createConfirmedUser(supabase, { email, password, fullName, phone, role }) {
  const data = await requireOk(
    `create auth user ${email}`,
    await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: fullName,
        phone,
        role,
      },
    }),
  );

  return data.user;
}

async function main() {
  const env = readEnv();
  assert(env.NEXT_PUBLIC_SUPABASE_URL, 'Missing NEXT_PUBLIC_SUPABASE_URL');
  assert(env.NEXT_PUBLIC_SUPABASE_ANON_KEY, 'Missing NEXT_PUBLIC_SUPABASE_ANON_KEY');
  assert(env.SUPABASE_SERVICE_ROLE_KEY, 'Missing SUPABASE_SERVICE_ROLE_KEY');
  assert(process.env.LIVE_TEST_PASSWORD, 'Missing process-only LIVE_TEST_PASSWORD');

  const supabase = createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    },
  );
  const workerSessionClient = createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    },
  );

  const stamp = Date.now();
  const password = process.env.LIVE_TEST_PASSWORD;
  const workerEmail = `worker.demo.${stamp}@mediconnect.test`;
  const patientEmail = `patient.demo.${stamp}@mediconnect.test`;

  const category = await requireOk(
    'read Injection service category',
    await supabase
      .from('service_categories')
      .select('id,name_en')
      .eq('name_en', 'Injection')
      .single(),
  );

  const categories = await requireOk(
    'read all service categories',
    await supabase.from('service_categories').select('id'),
  );
  assert(categories.length >= 7, 'Expected seeded service categories');

  const workerUser = await createConfirmedUser(supabase, {
    email: workerEmail,
    password,
    fullName: `Demo Nurse ${stamp}`,
    phone: '+92 300 1111111',
    role: 'health_worker',
  });

  await requireOk(
    'insert worker profile',
    await supabase.from('profiles').insert({
      id: workerUser.id,
      role: 'health_worker',
      full_name: `Demo Nurse ${stamp}`,
      phone: '+92 300 1111111',
      email: workerEmail,
      preferred_language: 'en',
    }),
  );

  const worker = await requireOk(
    'insert pending worker',
    await supabase
      .from('health_workers')
      .insert({
        user_id: workerUser.id,
        worker_type: 'nurse',
        qualification: 'Registered Nurse',
        experience_years: 4,
        city: 'Karachi',
        service_area: 'Gulshan-e-Iqbal',
        bio: 'Live Supabase end-to-end test worker.',
      })
      .select('id,verification_status')
      .single(),
  );
  assert(worker.verification_status === 'pending', 'Worker should start pending');

  await requireOk(
    'insert worker documents',
    await supabase.from('worker_documents').insert([
      {
        worker_id: worker.id,
        document_type: 'cnic',
        file_path: `demo/${stamp}/cnic-reference`,
      },
      {
        worker_id: worker.id,
        document_type: 'certificate',
        file_path: `demo/${stamp}/certificate-reference`,
      },
    ]),
  );

  await requireOk(
    'insert worker wallet',
    await supabase.from('wallets').insert({
      worker_id: worker.id,
      balance_pkr: 2000,
    }),
  );

  await requireOk(
    'insert worker service',
    await supabase.from('worker_services').insert({
      worker_id: worker.id,
      service_category_id: category.id,
      base_price_pkr: 1200,
      is_active: true,
    }),
  );

  await requireOk(
    'approve worker',
    await supabase
      .from('health_workers')
      .update({
        verification_status: 'approved',
        is_available: true,
        rejection_reason: null,
      })
      .eq('id', worker.id),
  );

  await requireOk(
    'approve worker documents',
    await supabase
      .from('worker_documents')
      .update({
        status: 'approved',
        rejection_reason: null,
      })
      .eq('worker_id', worker.id),
  );

  const patientUser = await createConfirmedUser(supabase, {
    email: patientEmail,
    password,
    fullName: `Demo Patient ${stamp}`,
    phone: '+92 300 2222222',
    role: 'patient',
  });

  await requireOk(
    'insert patient profile',
    await supabase.from('profiles').insert({
      id: patientUser.id,
      role: 'patient',
      full_name: `Demo Patient ${stamp}`,
      phone: '+92 300 2222222',
      email: patientEmail,
      preferred_language: 'en',
    }),
  );

  const patient = await requireOk(
    'insert patient record',
    await supabase
      .from('patients')
      .insert({
        user_id: patientUser.id,
        gender: 'female',
        address: 'Demo House, Block 7',
        city: 'Karachi',
        emergency_contact_phone: '+92 300 3333333',
        medical_notes: 'Demo test patient record.',
      })
      .select('id')
      .single(),
  );

  const location = await requireOk(
    'insert patient location',
    await supabase
      .from('locations')
      .insert({
        user_id: patientUser.id,
        label: 'service request',
        address: 'Demo House, Block 7',
        city: 'Karachi',
        is_default: false,
      })
      .select('id')
      .single(),
  );

  const request = await requireOk(
    'insert service request',
    await supabase
      .from('service_requests')
      .insert({
        patient_id: patient.id,
        service_category_id: category.id,
        description: 'Demo injection service request.',
        location_id: location.id,
        status: 'searching',
      })
      .select('id,status')
      .single(),
  );

  const offer = await requireOk(
    'send worker offer',
    await supabase
      .from('service_request_offers')
      .insert({
        service_request_id: request.id,
        patient_id: patient.id,
        worker_id: worker.id,
        quoted_price_pkr: 1200,
        status: 'pending',
      })
      .select('id,status')
      .single(),
  );
  assert(offer.status === 'pending', 'Offer should start pending');

  await requireOk(
    'accept offer',
    await supabase
      .from('service_request_offers')
      .update({
        status: 'accepted',
        responded_at: new Date().toISOString(),
      })
      .eq('id', offer.id),
  );

  const order = await requireOk(
    'create accepted order',
    await supabase
      .from('orders')
      .insert({
        service_request_id: request.id,
        patient_id: patient.id,
        worker_id: worker.id,
        service_category_id: category.id,
        quoted_price_pkr: 1200,
        status: 'accepted',
        accepted_at: new Date().toISOString(),
      })
      .select('id,status')
      .single(),
  );

  await requireOk(
    'mark request accepted',
    await supabase
      .from('service_requests')
      .update({ status: 'accepted' })
      .eq('id', request.id),
  );

  await requireOk(
    'log accepted event',
    await supabase.from('order_events').insert({
      order_id: order.id,
      actor_user_id: workerUser.id,
      event_type: 'accepted',
      metadata: { offer_id: offer.id },
    }),
  );

  const chat = await requireOk(
    'create chat',
    await supabase
      .from('chats')
      .insert({
        order_id: order.id,
        patient_user_id: patientUser.id,
        worker_user_id: workerUser.id,
      })
      .select('id')
      .single(),
  );

  await requireOk(
    'insert chat messages',
    await supabase.from('messages').insert([
      {
        chat_id: chat.id,
        sender_user_id: patientUser.id,
        message_type: 'text',
        body: 'Demo patient message.',
      },
      {
        chat_id: chat.id,
        sender_user_id: workerUser.id,
        message_type: 'text',
        body: 'Demo worker reply.',
      },
    ]),
  );

  await requireOk(
    'sign in demo worker for order status RPCs',
    await workerSessionClient.auth.signInWithPassword({
      email: workerEmail,
      password,
    }),
  );

  await requireOk(
    'mark worker on way through RPC',
    await workerSessionClient.rpc('update_order_status_with_event', {
      target_order_id: order.id,
      target_status: 'worker_on_way',
      event_metadata: { source: 'live-e2e-test' },
    }),
  );

  await requireOk(
    'mark service started through RPC',
    await workerSessionClient.rpc('update_order_status_with_event', {
      target_order_id: order.id,
      target_status: 'started',
      event_metadata: { source: 'live-e2e-test' },
    }),
  );

  await requireOk(
    'complete order with commission',
    await workerSessionClient.rpc('complete_order_with_commission', {
      target_order_id: order.id,
      final_price: 1500,
    }),
  );

  const wallet = await requireOk(
    'read worker wallet after commission',
    await supabase
      .from('wallets')
      .select('id,balance_pkr')
      .eq('worker_id', worker.id)
      .single(),
  );
  assert(wallet.balance_pkr === 1850, `Expected wallet after commission to be 1850, got ${wallet.balance_pkr}`);

  const topUp = await requireOk(
    'insert wallet top-up request',
    await supabase
      .from('wallet_transactions')
      .insert({
        wallet_id: wallet.id,
        type: 'top_up',
        amount_pkr: 1000,
        direction: 'credit',
        status: 'pending',
        reference: 'JazzCash: DEMO-REF',
      })
      .select('id,status')
      .single(),
  );

  const reviewedTopUp = await requireOk(
    'approve wallet top-up through RPC',
    await supabase.rpc('review_wallet_top_up', {
      target_transaction_id: topUp.id,
      approve_top_up: true,
    }),
  );
  assert(reviewedTopUp.status === 'approved', 'Top-up should be approved');

  const finalChecks = await Promise.all([
    requireOk(
      'final order check',
      await supabase
        .from('orders')
        .select('status,final_price_pkr,platform_commission_pkr')
        .eq('id', order.id)
        .single(),
    ),
    requireOk(
      'final messages check',
      await supabase.from('messages').select('id').eq('chat_id', chat.id),
    ),
    requireOk(
      'final wallet check',
      await supabase
        .from('wallets')
        .select('balance_pkr')
        .eq('id', wallet.id)
        .single(),
    ),
  ]);

  const [finalOrder, messages, finalWallet] = finalChecks;
  assert(finalOrder.status === 'completed', 'Order should be completed');
  assert(finalOrder.final_price_pkr === 1500, 'Final price should be 1500');
  assert(finalOrder.platform_commission_pkr === 150, 'Commission should be 150');
  assert(messages.length === 2, 'Expected two chat messages');
  assert(finalWallet.balance_pkr === 2850, 'Expected final wallet balance 2850');

  console.log(
    JSON.stringify(
      {
        passed: true,
        note: 'All records use demo email/file patterns and are covered by cleanup_test_data_before_launch.sql.',
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
        },
        finalState: {
          orderStatus: finalOrder.status,
          finalPricePkr: finalOrder.final_price_pkr,
          platformCommissionPkr: finalOrder.platform_commission_pkr,
          walletBalancePkr: finalWallet.balance_pkr,
          messageCount: messages.length,
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
