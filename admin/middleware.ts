import { NextResponse, type NextRequest } from 'next/server';

import {
  adminCookieName,
  getAdminAuthMode,
  isValidAdminAccessToken,
  isValidAdminRoleCookieValue,
} from './lib/admin-access';

export async function middleware(request: NextRequest) {
  const mode = getAdminAuthMode();
  const accessCode = process.env.ADMIN_ACCESS_CODE;

  if (mode === 'access_code' && !accessCode) {
    return NextResponse.next();
  }

  const path = request.nextUrl.pathname;
  if (path === '/login' || path === '/api/health') {
    return NextResponse.next();
  }

  const cookie = request.cookies.get(adminCookieName)?.value;
  const hasAccess =
    mode === 'supabase_role'
      ? await isValidAdminRoleCookieValue(cookie)
      : await isValidAdminAccessToken(cookie, accessCode ?? '');

  if (hasAccess) {
    return NextResponse.next();
  }

  const loginUrl = request.nextUrl.clone();
  loginUrl.pathname = '/login';
  loginUrl.searchParams.set('next', path);
  return NextResponse.redirect(loginUrl);
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
