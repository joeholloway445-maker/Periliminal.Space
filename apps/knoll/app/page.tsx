import type { Metadata } from 'next'
import KnollDashboard from './KnollDashboard'

export const metadata: Metadata = {
  title: 'KNOLL — Security Arbiter',
  description: 'HDV security pipeline arbiter and threat monitor',
}

export default function KnollPage() {
  return <KnollDashboard />
}
