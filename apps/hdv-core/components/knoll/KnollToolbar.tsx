'use client'
import { useKnollStore } from '@/lib/knoll/store'
import type { ViewMode } from '@/lib/knoll/types'

const MODES: { value: ViewMode; label: string; desc: string }[] = [
  { value: 'overview',  label: 'Overview',  desc: '5 agents' },
  { value: 'expanded',  label: 'Expanded',  desc: '99 nodes' },
  { value: 'full',      label: 'Full',      desc: 'All data' },
]

export default function KnollToolbar() {
  const { viewMode, setViewMode } = useKnollStore()

  return (
    <div
      className="flex items-center gap-4 px-5 py-2.5"
      style={{
        background: 'rgba(15,15,26,0.92)',
        borderBottom: '1px solid rgba(239,68,68,0.2)',
        backdropFilter: 'blur(12px)',
      }}
    >
      {/* Wordmark */}
      <div className="flex items-center gap-2 mr-4">
        <div
          className="w-2 h-2 rounded-full"
          style={{ background: '#ef4444', boxShadow: '0 0 8px rgba(239,68,68,0.8)' }}
        />
        <span className="text-sm font-bold tracking-[0.2em] text-white uppercase">KNOLL</span>
        <span className="text-[10px] text-slate-500 tracking-widest uppercase">Security</span>
      </div>

      {/* View mode toggle */}
      <div
        className="flex rounded-lg overflow-hidden"
        style={{ border: '1px solid rgba(239,68,68,0.25)' }}
      >
        {MODES.map((m) => (
          <button
            key={m.value}
            onClick={() => setViewMode(m.value)}
            className="flex flex-col items-center px-4 py-1.5 text-xs transition-all cursor-pointer"
            style={{
              background: viewMode === m.value ? 'rgba(239,68,68,0.15)' : 'transparent',
              color: viewMode === m.value ? '#ef4444' : 'rgba(148,163,184,0.7)',
              borderRight: m.value !== 'full' ? '1px solid rgba(239,68,68,0.15)' : 'none',
            }}
          >
            <span className="font-semibold tracking-wide">{m.label}</span>
            <span className="text-[9px] opacity-60">{m.desc}</span>
          </button>
        ))}
      </div>

      {/* Spacer */}
      <div className="flex-1" />

      {/* Status indicators */}
      <div className="flex items-center gap-4 text-[10px] text-slate-500">
        <div className="flex items-center gap-1.5">
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" style={{ boxShadow: '0 0 4px rgba(52,211,153,0.8)' }} />
          <span>System Nominal</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="w-1.5 h-1.5 rounded-full bg-red-400" style={{ boxShadow: '0 0 4px rgba(248,113,113,0.8)' }} />
          <span>KNOLL Active</span>
        </div>
      </div>
    </div>
  )
}
