import type { Metadata } from 'next'
import { Geist_Mono } from 'next/font/google'
import './globals.css'

const geistMono = Geist_Mono({
  variable: '--font-geist-mono',
  subsets: ['latin'],
})

export const metadata: Metadata = {
  title: 'KNOLL — Security Arbiter',
  description: 'HDV security pipeline arbiter and threat monitor',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className={`${geistMono.variable} h-full`}>
      <body className="h-full antialiased" style={{ background: '#0a0a0a', color: '#e2e8f0' }}>
        {children}
      </body>
    </html>
  )
}
