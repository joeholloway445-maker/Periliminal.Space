'use client'
import { useKnollStore } from '@/lib/knoll/store'
import { useEffect } from 'react'
import { AGENTS } from '@/lib/knoll/agents'
import type { ActivityEntry } from '@/lib/knoll/types'

const statusColor: Record<string, string> = {
  active:  'text-emerald-400',
  idle:    'text-slate-400',
  error:   'text-red-400',
  standby: 'text-yellow-400',
}

const SAMPLE_ACTIONS = [
  { agentId: 'knoll', agentName: 'KNOLL', action: 'session.validated', target: 'user:joe', status: 'active' as const },
  { agentId: 'knoll', agentName: 'KNOLL', action: 'rls.policy.applied', target: 'knoll_activity_log', status: 'active' as const },
  { agentId: 'hope',  agentName: 'HOPE',  action: 'intent.parsed',     target: 'user input',          status: 'active' as const },
  { agentId: 'apex',  agentName: 'APEX',  action: 'task.routed',       target: 'dream-world-builder',  status: 'active' as const },
  { agentId: 'knoll', agentName: 'KNOLL', action: 'threat.scored',     target: 'ip:82.x.x.x',         status: 'active' as const },
  { agentId: 'apex',  agentName: 'APEX',  action: 'model.selected',    target: 'claude-sonnet-5',      status: 'active' as const },
]

export default function ActivityFeed() {
  const { activityFeed, pushActivity } = useKnollStore()

  useEffect(() => {
    const initial: ActivityEntry[] = SAMPLE_ACTIONS.map((a, i) => ({
      id: `init-${i}`,
      timestamp: new Date(Date.now() - (SAMPLE_ACTIONS.length - i) * 8000).toISOString(),
      latencyMs: Math.floor(Math.random() * 80) + 4,
      ...a,
    }))
    initial.forEach(e => pushActivity(e))

    const timer = setInterval(() => {
      const sample = SAMPLE_ACTIONS[Math.floor(Math.random() * SAMPLE_ACTIONS.length)]
      pushActivity({
        id: `live-${Date.now()}`,
        timestamp: new Date().toISOString(),
        latencyMs: Math.floor(Math.random() * 80) + 4,
        ...sample,
      })
    }, 4000)

    return () => clearInterval(timer)
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const agentColor = (agentId: string) =>
    AGENTS.find(a => a.id === agentId)?.primaryColor ?? '#94a3b8'

  const fmt = (iso: string) =>
    new Date(iso).toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' })

  return (
    <div className="flex flex-col h-full">
      <div className="px-4 py-2.5 flex items-center gap-2" style={{ borderBottom: '1px solid rgba(239,68,68,0.1)' }}>
        <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" style={{ boxShadow: '0 0 4px rgba(52,211,153,0.8)' }} />
        <span className="text-[10px] uppercase tracking-widest text-slate-400">Live Activity</span>
        <span className="ml-auto text-[10px] text-slate-600">{activityFeed.length}</span>
      </div>
      <div className="flex-1 overflow-y-auto">
        {activityFeed.map((entry) => (
          <div
            key={entry.id}
            className="px-4 py-2 border-b"
            style={{ borderColor: 'rgba(255,255,255,0.03)' }}
          >
            <div className="flex items-center gap-1.5 mb-0.5">
              <span
                className="text-[9px] font-bold tracking-wider uppercase"
                style={{ color: agentColor(entry.agentId) }}
              >
                {entry.agentName}
              </span>
              <span className="text-[9px] text-slate-600 font-mono">{fmt(entry.timestamp)}</span>
              {entry.latencyMs && (
                <span className="ml-auto text-[9px] text-slate-600">{entry.latencyMs}ms</span>
              )}
            </div>
            <div className="flex items-center gap-1.5">
              <span className="text-[10px] font-mono text-slate-300">{entry.action}</span>
              <span className="text-[9px] text-slate-500">→ {entry.target}</span>
            </div>
            <span className={`text-[9px] font-medium ${statusColor[entry.status]}`}>
              {entry.status}
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}
