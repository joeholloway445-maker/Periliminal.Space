'use client'
import { useKnollStore } from '@/lib/knoll/store'
import { AGENTS } from '@/lib/knoll/agents'

const KNOLL = AGENTS.find(a => a.id === 'knoll')!
const activeCount = KNOLL.children.filter(c => c.status === 'active').length
const standbyCount = KNOLL.children.filter(c => c.status === 'standby').length

const FONT = { fontFamily: 'var(--font-geist-mono, "GeistMono", monospace)' }

export default function KnollToolbar() {
  const { activityFeed } = useKnollStore()
  const threatCount = activityFeed.filter(e => e.action.includes('threat')).length

  return (
    <div
      style={{
        ...FONT,
        display: 'flex',
        alignItems: 'center',
        gap: 24,
        padding: '0 20px',
        height: 48,
        background: '#0d0d0d',
        borderBottom: '1px solid rgba(239,68,68,0.18)',
        flexShrink: 0,
      }}
    >
      {/* Product wordmark */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginRight: 8 }}>
        <div style={{
          width: 28, height: 28, borderRadius: 6,
          background: '#ef4444',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 14,
        }}>⚔</div>
        <div>
          <div style={{ fontSize: 13, fontWeight: 700, color: '#fff', letterSpacing: '0.18em' }}>KNOLL</div>
          <div style={{ fontSize: 8, color: 'rgba(239,68,68,0.6)', letterSpacing: '0.2em', textTransform: 'uppercase', marginTop: 1 }}>Security Arbiter</div>
        </div>
      </div>

      {/* Divider */}
      <div style={{ width: 1, height: 28, background: 'rgba(255,255,255,0.06)' }} />

      {/* Pipeline stats */}
      <div style={{ display: 'flex', gap: 20 }}>
        <Stat label="Active" value={activeCount} color="#22c55e" />
        <Stat label="Standby" value={standbyCount} color="#f59e0b" />
        <Stat label="Threats" value={threatCount} color="#ef4444" />
        <Stat label="Policies" value={4} color="#94a3b8" />
      </div>

      <div style={{ flex: 1 }} />

      {/* Status badge */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 6,
          background: 'rgba(34,197,94,0.08)',
          border: '1px solid rgba(34,197,94,0.2)',
          borderRadius: 20,
          padding: '3px 10px',
        }}>
          <div style={{
            width: 6, height: 6, borderRadius: '50%',
            background: '#22c55e',
            boxShadow: '0 0 6px rgba(34,197,94,0.9)',
          }} />
          <span style={{ fontSize: 10, color: 'rgba(34,197,94,0.9)', letterSpacing: '0.1em' }}>NOMINAL</span>
        </div>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 6,
          border: '1px solid rgba(239,68,68,0.2)',
          borderRadius: 20,
          padding: '3px 10px',
        }}>
          <div style={{
            width: 6, height: 6, borderRadius: '50%',
            background: '#ef4444',
            boxShadow: '0 0 6px rgba(239,68,68,0.8)',
          }} />
          <span style={{ fontSize: 10, color: 'rgba(239,68,68,0.8)', letterSpacing: '0.1em' }}>LIVE</span>
        </div>
      </div>
    </div>
  )
}

function Stat({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
      <span style={{ fontSize: 15, fontWeight: 700, color, lineHeight: 1 }}>{value}</span>
      <span style={{ fontSize: 9, color: '#475569', textTransform: 'uppercase', letterSpacing: '0.12em' }}>{label}</span>
    </div>
  )
}
