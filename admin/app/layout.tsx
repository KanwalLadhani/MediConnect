import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'MediConnect Admin',
  description: 'Verification, orders, wallets, and operations for MediConnect.',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
