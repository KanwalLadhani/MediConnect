import { createSupabaseClient } from './supabase';
import {
  sanitizeAuditMetadata,
  type SafeAuditMetadataItem,
} from './admin-audit-metadata';

export type WorkerStatus = 'pending' | 'approved' | 'rejected' | 'suspended';

export type AdminWorker = {
  id: string;
  user_id: string;
  worker_type: string;
  qualification: string;
  experience_years: number | null;
  city: string;
  service_area: string | null;
  verification_status: WorkerStatus;
  rejection_reason: string | null;
  is_available: boolean;
  average_rating: number;
  total_reviews: number;
  total_completed_orders: number;
  created_at: string;
  profiles: {
    full_name: string;
    phone: string | null;
    email: string | null;
  } | null;
  worker_documents: WorkerDocument[];
  worker_services: WorkerService[];
};

export type WorkerDocument = {
  id: string;
  document_type: string;
  file_path: string;
  signedUrl?: string | null;
  status: 'pending' | 'approved' | 'rejected';
  rejection_reason: string | null;
  created_at: string;
};

export type WorkerService = {
  id: string;
  base_price_pkr: number;
  is_active: boolean;
  service_categories: {
    name_en: string;
  } | null;
};

export type AdminStats = {
  pendingVerifications: number;
  activeOrders: number;
  walletTopUps: number;
  openDisputes: number;
};

export type AdminWalletAnalytics = {
  totalWalletBalancePkr: number;
  negativeWallets: number;
  frozenWallets: number;
};

export type AdminPatient = {
  id: string;
  user_id: string;
  gender: string | null;
  address: string | null;
  city: string;
  medical_notes: string | null;
  created_at: string;
  requestCount: number;
  orderCount: number;
  reviewCount: number;
  profiles: {
    full_name: string;
    phone: string | null;
    email: string | null;
    is_active: boolean;
    preferred_language: string;
  } | null;
};

export type AdminPatientAnalytics = {
  totalPatients: number;
  activeProfiles: number;
  patientsWithOrders: number;
};

export type AdminServiceCategory = {
  id: string;
  name_en: string;
  name_ur: string;
  description_en: string | null;
  description_ur: string | null;
  is_active: boolean;
  created_at: string;
  requestCount: number;
  workerOfferingCount: number;
};

export type WalletTopUp = {
  id: string;
  amount_pkr: number;
  status: 'pending' | 'approved' | 'rejected' | 'completed';
  reference: string | null;
  screenshot_path: string | null;
  screenshotSignedUrl?: string | null;
  created_at: string;
  wallets: {
    id: string;
    balance_pkr: number;
    health_workers: {
      id: string;
      worker_type: string;
      profiles: {
        full_name: string;
        phone: string | null;
        email: string | null;
      } | null;
    } | null;
  } | null;
};

export type AdminOrder = {
  id: string;
  status: string;
  quoted_price_pkr: number;
  final_price_pkr: number | null;
  platform_commission_pkr: number | null;
  created_at: string;
  patients: {
    profiles: {
      full_name: string;
      phone: string | null;
      email: string | null;
    } | null;
  } | null;
  health_workers: {
    worker_type: string;
    profiles: {
      full_name: string;
      phone: string | null;
      email: string | null;
    } | null;
  } | null;
  service_requests: {
    description: string;
    image_path?: string | null;
    imageSignedUrl?: string | null;
    service_categories: {
      name_en: string;
    } | null;
    locations: {
      address: string;
      city: string;
    } | null;
  } | null;
  worker_locations: {
    latitude: number | string;
    longitude: number | string;
    created_at: string;
  }[];
};

export type AdminDispute = {
  id: string;
  order_id: string;
  reported_by: string;
  reason: string;
  details: string | null;
  status: 'open' | 'reviewing' | 'resolved' | 'rejected';
  resolution_notes: string | null;
  created_at: string;
  reporter?: {
    full_name: string;
    phone: string | null;
    email: string | null;
  } | null;
  orders: {
    id: string;
    status: string;
    quoted_price_pkr: number;
    final_price_pkr: number | null;
    service_requests: {
      description: string;
      service_categories: {
        name_en: string;
      } | null;
      locations: {
        address: string;
        city: string;
      } | null;
    } | null;
  } | null;
};

export type AdminReview = {
  id: string;
  rating: number;
  review_text: string | null;
  created_at: string;
  patients: {
    profiles: {
      full_name: string;
      phone: string | null;
      email: string | null;
    } | null;
  } | null;
  health_workers: {
    worker_type: string;
    profiles: {
      full_name: string;
      phone: string | null;
      email: string | null;
    } | null;
  } | null;
  orders: {
    id: string;
    status: string;
    final_price_pkr: number | null;
    service_requests: {
      description: string;
      service_categories: {
        name_en: string;
      } | null;
      locations: {
        address: string;
        city: string;
      } | null;
    } | null;
  } | null;
};

export type AdminOrderEvent = {
  id: string;
  order_id: string;
  actor_user_id: string | null;
  event_type: string;
  metadata: Record<string, unknown>;
  created_at: string;
  profiles: {
    full_name: string;
    phone: string | null;
    email: string | null;
    role: string;
  } | null;
  orders: {
    id: string;
    status: string;
    quoted_price_pkr: number;
    final_price_pkr: number | null;
    service_requests: {
      description: string;
      service_categories: {
        name_en: string;
      } | null;
      locations: {
        address: string;
        city: string;
      } | null;
    } | null;
  } | null;
};

export type AdminAuditLog = {
  id: string;
  actor_user_id: string | null;
  type: string;
  action: string;
  metadata: Record<string, unknown>;
  created_at: string;
  profiles: {
    full_name: string;
    role: string;
  } | null;
};

export type AdminAuditTimelineEntry = {
  id: string;
  source: 'order_event' | 'admin_audit_log';
  title: string;
  category: string;
  created_at: string;
  actorUserId: string | null;
  actorName: string;
  actorRole: string;
  orderId?: string;
  orderStatus?: string;
  serviceName?: string;
  locationLabel?: string;
  metadata: SafeAuditMetadataItem[];
};

type AdminAuditType =
  | 'worker_verification'
  | 'wallet_top_up'
  | 'dispute_review'
  | 'service_category';

export type AdminMedicalRecord = {
  id: string;
  order_id: string | null;
  notes: string | null;
  file_path: string | null;
  fileSignedUrl?: string | null;
  created_at: string;
  health_workers: {
    worker_type: string;
    profiles: {
      full_name: string;
      phone: string | null;
      email: string | null;
    } | null;
  } | null;
};

export type AdminChatMessage = {
  id: string;
  sender_user_id: string;
  message_type: 'text' | 'image';
  body: string | null;
  file_path: string | null;
  fileSignedUrl?: string | null;
  created_at: string;
  sender?: {
    full_name: string;
    role: string;
  } | null;
};

const workerSelect = `
  id,
  user_id,
  worker_type,
  qualification,
  experience_years,
  city,
  service_area,
  verification_status,
  rejection_reason,
  is_available,
  average_rating,
  total_reviews,
  total_completed_orders,
  created_at,
  profiles(full_name, phone, email),
  worker_documents(id, document_type, file_path, status, rejection_reason, created_at),
  worker_services(id, base_price_pkr, is_active, service_categories(name_en))
`;

export async function getAdminStats(): Promise<AdminStats> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return {
      pendingVerifications: 0,
      activeOrders: 0,
      walletTopUps: 0,
      openDisputes: 0,
    };
  }

  const [workers, orders, topUps, disputes] = await Promise.all([
    supabase
      .from('health_workers')
      .select('id', { count: 'exact', head: true })
      .eq('verification_status', 'pending'),
    supabase
      .from('orders')
      .select('id', { count: 'exact', head: true })
      .in('status', ['accepted', 'worker_on_way', 'started', 'disputed']),
    supabase
      .from('wallet_transactions')
      .select('id', { count: 'exact', head: true })
      .eq('type', 'top_up')
      .eq('status', 'pending'),
    supabase
      .from('disputes')
      .select('id', { count: 'exact', head: true })
      .in('status', ['open', 'reviewing']),
  ]);

  return {
    pendingVerifications: workers.count ?? 0,
    activeOrders: orders.count ?? 0,
    walletTopUps: topUps.count ?? 0,
    openDisputes: disputes.count ?? 0,
  };
}

export async function getWorkers(status?: WorkerStatus): Promise<AdminWorker[]> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return [];
  }

  let query = supabase
    .from('health_workers')
    .select(workerSelect)
    .order('created_at', { ascending: false });

  if (status) {
    query = query.eq('verification_status', status);
  }

  const { data, error } = await query;

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as unknown as AdminWorker[];
}

export async function getWorker(workerId: string): Promise<AdminWorker | null> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return null;
  }

  const { data, error } = await supabase
    .from('health_workers')
    .select(workerSelect)
    .eq('id', workerId)
    .single();

  if (error) {
    if (error.code === 'PGRST116') {
      return null;
    }

    throw new Error(error.message);
  }

  const worker = data as unknown as AdminWorker;

  worker.worker_documents = await Promise.all(
    worker.worker_documents.map(async (document) => ({
      ...document,
      signedUrl: await createWorkerDocumentSignedUrl(document.file_path),
    })),
  );

  return worker;
}

export async function getAdminPatients(): Promise<AdminPatient[]> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return [];
  }

  const { data, error } = await supabase
    .from('patients')
    .select(
      `
        id,
        user_id,
        gender,
        address,
        city,
        medical_notes,
        created_at,
        profiles(full_name, phone, email, is_active, preferred_language)
      `,
    )
    .order('created_at', { ascending: false })
    .limit(100);

  if (error) {
    throw new Error(error.message);
  }

  const patients = (data ?? []) as unknown as Omit<
    AdminPatient,
    'requestCount' | 'orderCount' | 'reviewCount'
  >[];
  const patientIds = patients.map((patient) => patient.id);

  if (patientIds.length === 0) {
    return [];
  }

  const [requests, orders, reviews] = await Promise.all([
    supabase.from('service_requests').select('patient_id').in('patient_id', patientIds),
    supabase.from('orders').select('patient_id').in('patient_id', patientIds),
    supabase.from('reviews').select('patient_id').in('patient_id', patientIds),
  ]);

  for (const result of [requests, orders, reviews]) {
    if (result.error) {
      throw new Error(result.error.message);
    }
  }

  const requestCounts = countByPatient(requests.data ?? []);
  const orderCounts = countByPatient(orders.data ?? []);
  const reviewCounts = countByPatient(reviews.data ?? []);

  return patients.map((patient) => ({
    ...patient,
    requestCount: requestCounts.get(patient.id) ?? 0,
    orderCount: orderCounts.get(patient.id) ?? 0,
    reviewCount: reviewCounts.get(patient.id) ?? 0,
  }));
}

export async function getAdminPatient(
  patientId: string,
): Promise<AdminPatient | null> {
  const patients = await getAdminPatients();
  return patients.find((patient) => patient.id === patientId) ?? null;
}

export async function getAdminOrdersForPatient(
  patientId: string,
): Promise<AdminOrder[]> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return [];
  }

  const { data, error } = await supabase
    .from('orders')
    .select(
      `
        id,
        status,
        quoted_price_pkr,
        final_price_pkr,
        platform_commission_pkr,
        created_at,
        patients(profiles(full_name, phone, email)),
        health_workers(worker_type, profiles(full_name, phone, email)),
        service_requests(
          description,
          image_path,
          service_categories(name_en),
          locations(address, city)
        ),
        worker_locations(latitude, longitude, created_at)
      `,
    )
    .eq('patient_id', patientId)
    .order('created_at', { ascending: false })
    .limit(50);

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as unknown as AdminOrder[];
}

export async function getAdminMedicalRecordsForPatient(
  patientId: string,
): Promise<AdminMedicalRecord[]> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return [];
  }

  const { data, error } = await supabase
    .from('medical_records')
    .select(
      `
        id,
        order_id,
        notes,
        file_path,
        created_at,
        health_workers(worker_type, profiles(full_name, phone, email))
      `,
    )
    .eq('patient_id', patientId)
    .order('created_at', { ascending: false })
    .limit(50);

  if (error) {
    throw new Error(error.message);
  }

  const records = (data ?? []) as unknown as AdminMedicalRecord[];

  return Promise.all(
    records.map(async (record) => ({
      ...record,
      fileSignedUrl: record.file_path
        ? await createStorageSignedUrl('medical-records', record.file_path)
        : null,
    })),
  );
}

export async function getAdminMedicalRecordsForOrder(
  orderId: string,
): Promise<AdminMedicalRecord[]> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return [];
  }

  const { data, error } = await supabase
    .from('medical_records')
    .select(
      `
        id,
        order_id,
        notes,
        file_path,
        created_at,
        health_workers(worker_type, profiles(full_name, phone, email))
      `,
    )
    .eq('order_id', orderId)
    .order('created_at', { ascending: false });

  if (error) {
    throw new Error(error.message);
  }

  const records = (data ?? []) as unknown as AdminMedicalRecord[];

  return Promise.all(
    records.map(async (record) => ({
      ...record,
      fileSignedUrl: record.file_path
        ? await createStorageSignedUrl('medical-records', record.file_path)
        : null,
    })),
  );
}

export async function getAdminOrdersForWorker(
  workerId: string,
): Promise<AdminOrder[]> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return [];
  }

  const { data, error } = await supabase
    .from('orders')
    .select(
      `
        id,
        status,
        quoted_price_pkr,
        final_price_pkr,
        platform_commission_pkr,
        created_at,
        patients(profiles(full_name, phone, email)),
        health_workers(worker_type, profiles(full_name, phone, email)),
        service_requests(
          description,
          image_path,
          service_categories(name_en),
          locations(address, city)
        ),
        worker_locations(latitude, longitude, created_at)
      `,
    )
    .eq('worker_id', workerId)
    .order('created_at', { ascending: false })
    .limit(50);

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as unknown as AdminOrder[];
}

export async function getAdminPatientAnalytics(): Promise<AdminPatientAnalytics> {
  const patients = await getAdminPatients();

  return {
    totalPatients: patients.length,
    activeProfiles: patients.filter((patient) => patient.profiles?.is_active).length,
    patientsWithOrders: patients.filter((patient) => patient.orderCount > 0).length,
  };
}

export async function getAdminServiceCategories(): Promise<AdminServiceCategory[]> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return [];
  }

  const { data, error } = await supabase
    .from('service_categories')
    .select(
      `
        id,
        name_en,
        name_ur,
        description_en,
        description_ur,
        is_active,
        created_at
      `,
    )
    .order('name_en', { ascending: true });

  if (error) {
    throw new Error(error.message);
  }

  const categories = (data ?? []) as Omit<
    AdminServiceCategory,
    'requestCount' | 'workerOfferingCount'
  >[];
  const categoryIds = categories.map((category) => category.id);

  if (categoryIds.length === 0) {
    return [];
  }

  const [requests, workerServices] = await Promise.all([
    supabase
      .from('service_requests')
      .select('service_category_id')
      .in('service_category_id', categoryIds),
    supabase
      .from('worker_services')
      .select('service_category_id')
      .eq('is_active', true)
      .in('service_category_id', categoryIds),
  ]);

  for (const result of [requests, workerServices]) {
    if (result.error) {
      throw new Error(result.error.message);
    }
  }

  const requestCounts = countByCategory(requests.data ?? []);
  const workerOfferingCounts = countByCategory(workerServices.data ?? []);

  return categories.map((category) => ({
    ...category,
    requestCount: requestCounts.get(category.id) ?? 0,
    workerOfferingCount: workerOfferingCounts.get(category.id) ?? 0,
  }));
}

export async function updateServiceCategoryStatus({
  categoryId,
  isActive,
  actorUserId,
}: {
  categoryId: string;
  isActive: boolean;
  actorUserId?: string | null;
}) {
  const supabase = createSupabaseClient();

  if (!supabase) {
    throw new Error('Supabase environment variables are not configured.');
  }

  const { error } = await supabase
    .from('service_categories')
    .update({ is_active: isActive })
    .eq('id', categoryId);

  if (error) {
    throw new Error(error.message);
  }

  await insertAdminAuditLog(supabase, {
    actorUserId,
    type: 'service_category',
    action: isActive ? 'activated' : 'deactivated',
    metadata: {
      category_id: categoryId,
      is_active: isActive,
    },
  });
}

export async function updateWorkerVerification({
  workerId,
  status,
  rejectionReason,
  actorUserId,
}: {
  workerId: string;
  status: WorkerStatus;
  rejectionReason?: string;
  actorUserId?: string | null;
}) {
  const supabase = createSupabaseClient();

  if (!supabase) {
    throw new Error('Supabase environment variables are not configured.');
  }

  const hasWorkerDecisionNote = Boolean(rejectionReason?.trim());
  const { error } = await supabase
    .from('health_workers')
    .update({
      verification_status: status,
      rejection_reason: status === 'rejected' ? rejectionReason ?? null : null,
    })
    .eq('id', workerId);

  if (error) {
    throw new Error(error.message);
  }

  const { data: worker, error: workerError } = await supabase
    .from('health_workers')
    .select('user_id')
    .eq('id', workerId)
    .single();

  if (workerError) {
    throw new Error(workerError.message);
  }

  const notification = notificationForWorkerStatus(status, rejectionReason);
  if (notification) {
    const { error: notificationError } = await supabase.from('notifications').insert({
      user_id: worker.user_id,
      title: notification.title,
      body: notification.body,
      type: 'verification',
    });

    if (notificationError) {
      throw new Error(notificationError.message);
    }
  }

  if (status === 'approved') {
    await supabase
      .from('worker_documents')
      .update({ status: 'approved', rejection_reason: null })
      .eq('worker_id', workerId);
  }

  await insertAdminAuditLog(supabase, {
    actorUserId,
    type: 'worker_verification',
    action: `set_${status}`,
    metadata: {
      worker_id: workerId,
      status,
      has_rejection_reason: hasWorkerDecisionNote,
    },
  });
}

function notificationForWorkerStatus(status: WorkerStatus, rejectionReason?: string) {
  if (status === 'approved') {
    return {
      title: 'Worker profile approved',
      body: 'Your MediConnect worker profile is approved. You can now turn availability on and accept requests.',
    };
  }

  if (status === 'rejected') {
    return {
      title: 'Worker profile needs changes',
      body: rejectionReason || 'Please review your profile and documents, then resubmit for verification.',
    };
  }

  if (status === 'suspended') {
    return {
      title: 'Worker profile suspended',
      body: 'Your worker access is suspended. Contact MediConnect admin for support.',
    };
  }

  return null;
}

export async function getPendingWalletTopUps(): Promise<WalletTopUp[]> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return [];
  }

  const { data, error } = await supabase
    .from('wallet_transactions')
    .select(
      `
        id,
        amount_pkr,
        status,
        reference,
        screenshot_path,
        created_at,
        wallets(
          id,
          balance_pkr,
          health_workers(
            id,
            worker_type,
            profiles(full_name, phone, email)
          )
        )
      `,
    )
    .eq('type', 'top_up')
    .eq('direction', 'credit')
    .eq('status', 'pending')
    .order('created_at', { ascending: true });

  if (error) {
    throw new Error(error.message);
  }

  const topUps = (data ?? []) as unknown as WalletTopUp[];

  return Promise.all(
    topUps.map(async (topUp) => ({
      ...topUp,
      screenshotSignedUrl: topUp.screenshot_path
        ? await createStorageSignedUrl('wallet-topups', topUp.screenshot_path)
        : null,
    })),
  );
}

export async function reviewWalletTopUp({
  transactionId,
  approved,
  actorUserId,
}: {
  transactionId: string;
  approved: boolean;
  actorUserId?: string | null;
}) {
  const supabase = createSupabaseClient();

  if (!supabase) {
    throw new Error('Supabase environment variables are not configured.');
  }

  const { error } = await supabase.rpc('review_wallet_top_up', {
    target_transaction_id: transactionId,
    approve_top_up: approved,
  });

  if (error) {
    throw new Error(error.message);
  }

  await insertAdminAuditLog(supabase, {
    actorUserId,
    type: 'wallet_top_up',
    action: approved ? 'approved' : 'rejected',
    metadata: {
      transaction_id: transactionId,
      approved,
    },
  });
}

export async function getAdminOrders(status?: string): Promise<AdminOrder[]> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return [];
  }

  let query = supabase
    .from('orders')
    .select(
      `
        id,
        status,
        quoted_price_pkr,
        final_price_pkr,
        platform_commission_pkr,
        created_at,
        patients(profiles(full_name, phone, email)),
        health_workers(worker_type, profiles(full_name, phone, email)),
        service_requests(
          description,
          service_categories(name_en),
          locations(address, city)
        ),
        worker_locations(latitude, longitude, created_at)
      `,
    )
    .order('created_at', { ascending: false })
    .limit(100);

  if (status) {
    query = query.eq('status', status);
  }

  const { data, error } = await query;

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as unknown as AdminOrder[];
}

export async function getAdminOrder(orderId: string): Promise<AdminOrder | null> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return null;
  }

  const { data, error } = await supabase
    .from('orders')
    .select(
      `
        id,
        status,
        quoted_price_pkr,
        final_price_pkr,
        platform_commission_pkr,
        created_at,
        patients(profiles(full_name, phone, email)),
        health_workers(worker_type, profiles(full_name, phone, email)),
        service_requests(
          description,
          image_path,
          service_categories(name_en),
          locations(address, city)
        ),
        worker_locations(latitude, longitude, created_at)
      `,
    )
    .eq('id', orderId)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }

  const order = data as unknown as AdminOrder | null;

  if (order?.service_requests?.image_path) {
    order.service_requests.imageSignedUrl = await createStorageSignedUrl(
      'service-request-images',
      order.service_requests.image_path,
    );
  }

  return order;
}

export async function getAdminOrderAnalytics() {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return {
      completedOrders: 0,
      totalCommissionPkr: 0,
      completedGrossPkr: 0,
      availableWorkers: 0,
    };
  }

  const [orders, workers] = await Promise.all([
    supabase
      .from('orders')
      .select('final_price_pkr, platform_commission_pkr')
      .eq('status', 'completed'),
    supabase
      .from('health_workers')
      .select('id', { count: 'exact', head: true })
      .eq('verification_status', 'approved')
      .eq('is_available', true),
  ]);

  if (orders.error) {
    throw new Error(orders.error.message);
  }

  return {
    completedOrders: orders.data?.length ?? 0,
    totalCommissionPkr:
      orders.data?.reduce(
        (total, order) => total + (order.platform_commission_pkr ?? 0),
        0,
      ) ?? 0,
    completedGrossPkr:
      orders.data?.reduce(
        (total, order) => total + (order.final_price_pkr ?? 0),
        0,
      ) ?? 0,
    availableWorkers: workers.count ?? 0,
  };
}

export async function getAdminWalletAnalytics(): Promise<AdminWalletAnalytics> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return {
      totalWalletBalancePkr: 0,
      negativeWallets: 0,
      frozenWallets: 0,
    };
  }

  const { data, error } = await supabase
    .from('wallets')
    .select('balance_pkr, status');

  if (error) {
    throw new Error(error.message);
  }

  const wallets = data ?? [];

  return {
    totalWalletBalancePkr: wallets.reduce(
      (total, wallet) => total + (wallet.balance_pkr ?? 0),
      0,
    ),
    negativeWallets: wallets.filter((wallet) => (wallet.balance_pkr ?? 0) < 0)
      .length,
    frozenWallets: wallets.filter((wallet) => wallet.status === 'frozen')
      .length,
  };
}

export async function getAdminDisputes(status?: string): Promise<AdminDispute[]> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return [];
  }

  let query = supabase
    .from('disputes')
    .select(
      `
        id,
        order_id,
        reported_by,
        reason,
        details,
        status,
        resolution_notes,
        created_at,
        orders(
          id,
          status,
          quoted_price_pkr,
          final_price_pkr,
          service_requests(
            description,
            service_categories(name_en),
            locations(address, city)
          )
        )
      `,
    )
    .order('created_at', { ascending: false });

  if (status) {
    query = query.eq('status', status);
  }

  const { data, error } = await query;

  if (error) {
    throw new Error(error.message);
  }

  const disputes = (data ?? []) as unknown as AdminDispute[];
  const reporterIds = Array.from(new Set(disputes.map((item) => item.reported_by)));
  if (reporterIds.length === 0) {
    return disputes;
  }

  const { data: profiles, error: profileError } = await supabase
    .from('profiles')
    .select('id, full_name, phone, email')
    .in('id', reporterIds);

  if (profileError) {
    throw new Error(profileError.message);
  }

  const profilesById = new Map(
    (profiles ?? []).map((profile) => [
      profile.id,
      {
        full_name: profile.full_name,
        phone: profile.phone,
        email: profile.email,
      },
    ]),
  );

  return disputes.map((dispute) => ({
    ...dispute,
    reporter: profilesById.get(dispute.reported_by) ?? null,
  }));
}

export async function updateDisputeStatus({
  disputeId,
  status,
  resolutionNotes,
  actorUserId,
}: {
  disputeId: string;
  status: 'open' | 'reviewing' | 'resolved' | 'rejected';
  resolutionNotes?: string;
  actorUserId?: string | null;
}) {
  const supabase = createSupabaseClient();

  if (!supabase) {
    throw new Error('Supabase environment variables are not configured.');
  }

  const updates: Record<string, string | null> = {
    status,
    resolution_notes: resolutionNotes?.trim() || null,
  };
  const hasDisputeDecisionNote = Boolean(resolutionNotes?.trim());

  if (status === 'resolved' || status === 'rejected') {
    updates.resolved_at = new Date().toISOString();
  }

  const { error } = await supabase
    .from('disputes')
    .update(updates)
    .eq('id', disputeId);

  if (error) {
    throw new Error(error.message);
  }

  await insertAdminAuditLog(supabase, {
    actorUserId,
    type: 'dispute_review',
    action: `set_${status}`,
    metadata: {
      dispute_id: disputeId,
      status,
      has_resolution_notes: hasDisputeDecisionNote,
    },
  });
}

export async function getAdminReviews(): Promise<AdminReview[]> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return [];
  }

  const { data, error } = await supabase
    .from('reviews')
    .select(
      `
        id,
        rating,
        review_text,
        created_at,
        patients(profiles(full_name, phone, email)),
        health_workers(worker_type, profiles(full_name, phone, email)),
        orders(
          id,
          status,
          final_price_pkr,
          service_requests(
            description,
            service_categories(name_en),
            locations(address, city)
          )
        )
      `,
    )
    .order('created_at', { ascending: false })
    .limit(100);

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as unknown as AdminReview[];
}

export async function getAdminReviewAnalytics() {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return {
      totalReviews: 0,
      averageRating: 0,
      lowRatingCount: 0,
    };
  }

  const { data, error } = await supabase.from('reviews').select('rating');

  if (error) {
    throw new Error(error.message);
  }

  const reviews = data ?? [];
  const totalReviews = reviews.length;
  const ratingTotal = reviews.reduce((total, review) => total + review.rating, 0);

  return {
    totalReviews,
    averageRating: totalReviews === 0 ? 0 : ratingTotal / totalReviews,
    lowRatingCount: reviews.filter((review) => review.rating <= 2).length,
  };
}

export async function getAdminOrderEvents(): Promise<AdminOrderEvent[]> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return [];
  }

  const { data, error } = await supabase
    .from('order_events')
    .select(
      `
        id,
        order_id,
        actor_user_id,
        event_type,
        metadata,
        created_at,
        profiles(full_name, phone, email, role),
        orders(
          id,
          status,
          quoted_price_pkr,
          final_price_pkr,
          service_requests(
            description,
            service_categories(name_en),
            locations(address, city)
          )
        )
      `,
    )
    .order('created_at', { ascending: false })
    .limit(150);

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as unknown as AdminOrderEvent[];
}

export async function getAdminAuditLogs(): Promise<AdminAuditLog[]> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return [];
  }

  const { data, error } = await supabase
    .from('audit_logs')
    .select(
      `
        id,
        actor_user_id,
        type,
        action,
        metadata,
        created_at,
        profiles(full_name, role)
      `,
    )
    .order('created_at', { ascending: false })
    .limit(150);

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as unknown as AdminAuditLog[];
}

export async function getAdminAuditTimeline(): Promise<AdminAuditTimelineEntry[]> {
  const [orderEvents, auditLogs] = await Promise.all([
    getAdminOrderEvents(),
    getAdminAuditLogs(),
  ]);

  return [
    ...orderEvents.map(normalizeOrderEventAuditEntry),
    ...auditLogs.map(normalizeAdminAuditLogEntry),
  ]
    .sort(
      (a, b) =>
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
    )
    .slice(0, 200);
}

export async function getAdminOrderEventsForOrder(
  orderId: string,
): Promise<AdminOrderEvent[]> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return [];
  }

  const { data, error } = await supabase
    .from('order_events')
    .select(
      `
        id,
        order_id,
        actor_user_id,
        event_type,
        metadata,
        created_at,
        profiles(full_name, phone, email, role),
        orders(
          id,
          status,
          quoted_price_pkr,
          final_price_pkr,
          service_requests(
            description,
            service_categories(name_en),
            locations(address, city)
          )
        )
      `,
    )
    .eq('order_id', orderId)
    .order('created_at', { ascending: true });

  if (error) {
    throw new Error(error.message);
  }

  return (data ?? []) as unknown as AdminOrderEvent[];
}

export async function getAdminOrderMessages(
  orderId: string,
): Promise<AdminChatMessage[]> {
  const supabase = createSupabaseClient();

  if (!supabase) {
    return [];
  }

  const { data: chat, error: chatError } = await supabase
    .from('chats')
    .select('id')
    .eq('order_id', orderId)
    .maybeSingle();

  if (chatError) {
    throw new Error(chatError.message);
  }

  if (!chat) {
    return [];
  }

  const { data, error } = await supabase
    .from('messages')
    .select('id, sender_user_id, message_type, body, file_path, created_at')
    .eq('chat_id', chat.id)
    .order('created_at', { ascending: true });

  if (error) {
    throw new Error(error.message);
  }

  const messages = (data ?? []) as AdminChatMessage[];
  const senderIds = Array.from(
    new Set(messages.map((message) => message.sender_user_id)),
  );

  const { data: profiles, error: profileError } = senderIds.length
    ? await supabase
        .from('profiles')
        .select('id, full_name, role')
        .in('id', senderIds)
    : { data: [], error: null };

  if (profileError) {
    throw new Error(profileError.message);
  }

  const profilesById = new Map(
    (profiles ?? []).map((profile) => [
      profile.id,
      {
        full_name: profile.full_name,
        role: profile.role,
      },
    ]),
  );

  return Promise.all(
    messages.map(async (message) => ({
      ...message,
      sender: profilesById.get(message.sender_user_id) ?? null,
      fileSignedUrl: message.file_path
        ? await createStorageSignedUrl('chat-images', message.file_path)
        : null,
    })),
  );
}

function normalizeOrderEventAuditEntry(
  event: AdminOrderEvent,
): AdminAuditTimelineEntry {
  const request = event.orders?.service_requests;
  const location = request?.locations;

  return {
    id: `order_event:${event.id}`,
    source: 'order_event',
    title: event.event_type,
    category: 'order_event',
    created_at: event.created_at,
    actorUserId: event.actor_user_id,
    actorName: event.profiles?.full_name ?? 'System',
    actorRole: event.profiles?.role ?? 'system',
    orderId: event.order_id,
    orderStatus: event.orders?.status,
    serviceName: request?.service_categories?.name_en ?? undefined,
    locationLabel: location
      ? `${location.address ?? 'Address not set'}, ${location.city ?? 'city'}`
      : undefined,
    metadata: sanitizeAuditMetadata(event.metadata),
  };
}

function normalizeAdminAuditLogEntry(log: AdminAuditLog): AdminAuditTimelineEntry {
  return {
    id: `admin_audit_log:${log.id}`,
    source: 'admin_audit_log',
    title: log.action,
    category: log.type,
    created_at: log.created_at,
    actorUserId: log.actor_user_id,
    actorName: log.profiles?.full_name ?? (log.actor_user_id ? 'Admin' : 'System'),
    actorRole: log.profiles?.role ?? 'admin',
    metadata: sanitizeAuditMetadata(log.metadata),
  };
}

function countByPatient(rows: { patient_id: string }[]) {
  const counts = new Map<string, number>();

  for (const row of rows) {
    counts.set(row.patient_id, (counts.get(row.patient_id) ?? 0) + 1);
  }

  return counts;
}

function countByCategory(rows: { service_category_id: string }[]) {
  const counts = new Map<string, number>();

  for (const row of rows) {
    counts.set(
      row.service_category_id,
      (counts.get(row.service_category_id) ?? 0) + 1,
    );
  }

  return counts;
}

async function insertAdminAuditLog(
  supabase: NonNullable<ReturnType<typeof createSupabaseClient>>,
  input: {
    actorUserId?: string | null;
    type: AdminAuditType;
    action: string;
    metadata: Record<string, unknown>;
  },
) {
  const { error } = await supabase.from('audit_logs').insert({
    actor_user_id: input.actorUserId ?? null,
    type: input.type,
    action: input.action,
    metadata: input.metadata,
  });

  if (error) {
    throw new Error(error.message);
  }
}

async function createWorkerDocumentSignedUrl(filePath: string) {
  return createStorageSignedUrl('worker-documents', filePath);
}

async function createStorageSignedUrl(bucket: string, filePath: string) {
  const supabase = createSupabaseClient();

  if (!supabase || !filePath || filePath.startsWith('demo/')) {
    return null;
  }

  const { data, error } = await supabase.storage
    .from(bucket)
    .createSignedUrl(filePath, 10 * 60);

  if (error) {
    return null;
  }

  return data.signedUrl;
}
