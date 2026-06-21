import { NextResponse } from 'next/server';

import { deploymentHealthStatus } from '../../../lib/deployment-health';

export const dynamic = 'force-dynamic';

export function GET() {
  const status = deploymentHealthStatus(process.env);

  return NextResponse.json(
    {
      service: 'mediconnect-admin',
      status,
    },
    {
      status: status === 'ok' ? 200 : 503,
      headers: {
        'Cache-Control': 'no-store, max-age=0',
      },
    },
  );
}
