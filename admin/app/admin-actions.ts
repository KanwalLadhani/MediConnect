'use server';

import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';

import { adminCookieName } from '@/lib/admin-access';

export async function logoutAdmin() {
  const cookieStore = await cookies();
  cookieStore.delete(adminCookieName);
  redirect('/login');
}
