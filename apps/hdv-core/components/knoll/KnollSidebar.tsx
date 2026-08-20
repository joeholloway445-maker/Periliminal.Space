'use client'
import { useKnollStore } from '@/lib/knoll/store'
import { AGENTS } from '@/lib/knoll/agents'

const TABS = ['agents', 'tools', 'docs', 'repos'] as const
type Tab = typeof TABS[number]

const agentAccentMap: Record<string, { color: string; glow: string }> = {
  knoll:  { color: '#ef4444', glow: 'rgba(239,68,68,0.3)' },
  hope:   { color: '#8b5cf6', glow: 'rgba(139,92,246,0.3)' },
  apex:   { color: '#06b6d4', glow: 'rgba(6,182,212,0.3)' },
  dream:  { color: '#d946ef', glow: 'rgba(217,70,239,0.3)' },
  vision: { color: '#f59e0b', glow: 'rgba(245,158,11,0.3)' },
}

const statusDot: Record<string, string> = {
  active:  '#34d399',
  idle:    '#475569',
  error:   '#f87171',
  standby: '#fbbf24',
}

export default function KnollSidebar() {
  const { sidebarTab, setSidebarTab, selectedNodeId, setSelectedNode } = useKnollStore()

  return (
    <div
      className="flex flex-col h-full"
      style={{
        background: 'rgba(15,15,26,0.95)',
        borderRight: '1px solid rgba(239,68,68,0.15)',
      }}
    >
      {/* Tab bar */}
      <div className="flex" style={{ borderBottom: '1px solid rgba(239,68,68,0.15)' }}>
        {TABS.map((tab) => (
          <button
            key={tab}
            onClick={() => setSidebarTab(tab)}
            className="flex-1 py-2.5 text-[10px] uppercase tracking-widest font-semibold transition-colors cursor-pointer"
            style={{
              color: sidebarTab === tab ? '#ef4444' : 'rgba(148,163,184,0.5)',
              borderBottom: sidebarTab === tab ? '1.5px solid #ef4444' : '1.5px solid transparent',
              background: sidebarTab === tab ? 'rgba(239,68,68,0.05)' : 'transparent',
            }}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        {sidebarTab === 'agents' && (
          <div className="p-3 space-y-2">
            {AGENTS.map((agent) => {
              const acc = agentAccentMap[agent.id]
              const isSelected = selectedNodeId === agent.id
              return (
                <div key={agent.id}>
                  <button
                    onClick={() => setSelectedNode(isSelected ? null : agent.id)}
                    className="w-full text-left px-3 py-2.5 rounded-lg transition-all cursor-pointer"
                    style={{
                      background: isSelected ? acc.color + '15' : 'rgba(255,255,255,0.02)',
                      border: `1px solid ${isSelected ? acc.color + '60' : 'rgba(255,255,255,0.05)'}`,
                      boxShadow: isSelected ? `0 0 12px ${acc.glow}` : 'none',
                    }}
                  >
                    <div className="flex items-center gap-2">
                      <div
                        className="w-2 h-2 rounded-full flex-shrink-0"
                        style={{
                          background: acc.color,
                          boxShadow: `0 0 6px ${acc.glow}`,
                        }}
                      />
                      <span className="text-xs font-bold tracking-wider text-white">{agent.name}</span>
                      <div
                        className="w-1.5 h-1.5 rounded-full ml-auto"
                        style={{ background: statusDot[agent.status] }}
                      />
                    </div>
                    <div className="text-[10px] text-slate-500 mt-0.5 ml-4">{agent.role}</div>
                    <div className="flex gap-3 mt-1.5 ml-4 text-[9px] text-slate-600">
                      <span style={{ color: acc.color + 'aa' }}>{agent.children.length} nodes</span>
                      <span style={{ color: acc.color + 'aa' }}>{agent.tools.length} tools</span>
                    </div>
                  </button>

                  {isSelected && agent.children.length > 0 && (
                    <div className="ml-3 mt-1 space-y-1">
                      {agent.children.map((c) => (
                        <button
                          key={c.id}
                          onClick={() => setSelectedNode(c.id)}
                          className="w-full text-left px-2.5 py-1.5 rounded-md text-[10px] transition-colors cursor-pointer"
                          style={{
                            background: selectedNodeId === c.id ? acc.color + '10' : 'rgba(255,255,255,0.02)',
                            border: `1px solid ${selectedNodeId === c.id ? acc.color + '30' : 'transparent'}`,
                            color: selectedNodeId === c.id ? 'white' : 'rgba(148,163,184,0.7)',
                          }}
                        >
                          <div className="flex items-center gap-1.5">
                            <div className="w-1 h-1 rounded-full" style={{ background: statusDot[c.status] }} />
                            <span className="font-medium">{c.name}</span>
                            <span className="ml-auto text-[9px] opacity-50">{c.role}</span>
                          </div>
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              )
            })}
          </div>
        )}

        {sidebarTab === 'tools' && (
          <div className="p-3">
            {AGENTS.map((agent) => {
              const acc = agentAccentMap[agent.id]
              return (
                <div key={agent.id} className="mb-4">
                  <div
                    className="text-[9px] uppercase tracking-widest mb-1.5 px-1"
                    style={{ color: acc.color }}
                  >
                    {agent.name}
                  </div>
                  <div className="flex flex-wrap gap-1">
                    {agent.tools.map((t) => (
                      <span
                        key={t}
                        className="text-[9px] px-1.5 py-0.5 rounded font-mono"
                        style={{
                          background: acc.color + '12',
                          border: `1px solid ${acc.color}30`,
                          color: acc.color + 'bb',
                        }}
                      >
                        {t}
                      </span>
                    ))}
                  </div>
                </div>
              )
            })}
          </div>
        )}

        {sidebarTab === 'docs' && (
          <div className="p-4 flex flex-col items-center justify-center h-full">
            <p className="text-xs text-slate-600 text-center">Documents surface here when connected to Supabase.</p>
          </div>
        )}

        {sidebarTab === 'repos' && (
          <div className="p-3 space-y-2">
            {[
              { name: 'periliminal.space',      status: 'active',       desc: 'Main monorepo' },
              { name: 'hdv-agent-core',          status: 'active',       desc: 'Agent SDK' },
              { name: 'mistral-apex-nodes',      status: 'active',       desc: 'APEX nodes' },
              { name: 'sea-scyte',               status: 'active',       desc: 'Analytics' },
              { name: 'hope-studio',             status: 'active',       desc: 'HOPE frontend' },
              { name: 'hdv_foundation',          status: 'active',       desc: 'Infra / migrations' },
              { name: 'hdv-orchestrator',        status: 'active',       desc: 'Orchestration' },
              { name: 'periliminal_space_project', status: 'consolidating', desc: 'Godot game client' },
              { name: 'the-hdv-core',            status: 'archived',     desc: 'Legacy (deprecated)' },
            ].map((r) => (
              <div
                key={r.name}
                className="px-3 py-2 rounded-lg"
                style={{ background: 'rgba(255,255,255,0.02)', border: '1px solid rgba(255,255,255,0.05)' }}
              >
                <div className="flex items-center gap-2">
                  <span className="text-[10px] font-mono text-slate-300">{r.name}</span>
                  <span
                    className="ml-auto text-[9px] px-1.5 py-0.5 rounded"
                    style={{
                      background: r.status === 'active' ? 'rgba(52,211,153,0.1)' : r.status === 'archived' ? 'rgba(239,68,68,0.1)' : 'rgba(245,158,11,0.1)',
                      color: r.status === 'active' ? '#34d399' : r.status === 'archived' ? '#f87171' : '#fbbf24',
                    }}
                  >
                    {r.status}
                  </span>
                </div>
                <div className="text-[9px] text-slate-600 mt-0.5">{r.desc}</div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
