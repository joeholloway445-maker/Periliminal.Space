import type { Metadata } from 'next'
import KnollDashboard from './KnollDashboard'

export const metadata: Metadata = {
  title: 'KNOLL — Security Dashboard',
  description: 'Private HDV security arbiter and agent graph',
}

export default function KnollPage() {
  return <KnollDashboard />
}
