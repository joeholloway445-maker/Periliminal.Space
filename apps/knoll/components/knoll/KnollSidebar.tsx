'use client'
import { useKnollStore } from '@/lib/knoll/store'
import { AGENTS } from '@/lib/knoll/agents'

const KNOLL = AGENTS.find(a => a.id === 'knoll')!

const TABS = ['pipeline', 'tools', 'docs', 'repos'] as const
type Tab = typeof TABS[number]

const statusDot: Record<string, string> = {
  active:  '#22c55e',
  idle:    '#475569',
  error:   '#f87171',
  standby: '#f59e0b',
}

const FONT: React.CSSProperties = {
  fontFamily: 'var(--font-geist-mono, "GeistMono", monospace)',
}

const REPO_LIST = [
  { name: 'periliminal.space',         status: 'active',        desc: 'Main monorepo' },
  { name: 'hdv-agent-core',            status: 'active',        desc: 'Agent SDK' },
  { name: 'mistral-apex-nodes',        status: 'active',        desc: 'APEX nodes' },
  { name: 'sea-scyte',                 status: 'active',        desc: 'Analytics' },
  { name: 'hope-studio',               status: 'active',        desc: 'HOPE frontend' },
  { name: 'hdv_foundation',            status: 'active',        desc: 'Infra / migrations' },
  { name: 'hdv-orchestrator',          status: 'active',        desc: 'Orchestration' },
  { name: 'periliminal_space_project', status: 'consolidating', desc: 'Godot game client' },
  { name: 'the-hdv-core',              status: 'archived',      desc: 'Legacy (deprecated)' },
]

const repoStatusColor = (s: string) =>
  s === 'active' ? '#22c55e' : s === 'archived' ? '#f87171' : '#f59e0b'
const repoStatusBg = (s: string) =>
  s === 'active' ? 'rgba(34,197,94,0.08)' : s === 'archived' ? 'rgba(248,113,113,0.08)' : 'rgba(245,158,11,0.08)'

export default function KnollSidebar() {
  const { sidebarTab, setSidebarTab, selectedNodeId, setSelectedNode } = useKnollStore()

  return (
    <div style={{
      ...FONT,
      display: 'flex',
      flexDirection: 'column',
      height: '100%',
      background: '#0d0d0d',
      borderRight: '1px solid rgba(239,68,68,0.12)',
    }}>
      {/* Tab bar */}
      <div style={{ display: 'flex', borderBottom: '1px solid rgba(239,68,68,0.12)' }}>
        {TABS.map((tab) => (
          <button
            key={tab}
            onClick={() => setSidebarTab(tab as Tab)}
            style={{
              flex: 1,
              padding: '9px 0',
              fontSize: 9,
              textTransform: 'uppercase',
              letterSpacing: '0.12em',
              fontWeight: 600,
              cursor: 'pointer',
              border: 'none',
              borderBottom: sidebarTab === tab ? '1.5px solid #ef4444' : '1.5px solid transparent',
              background: sidebarTab === tab ? 'rgba(239,68,68,0.06)' : 'transparent',
              color: sidebarTab === tab ? '#ef4444' : 'rgba(148,163,184,0.45)',
              fontFamily: 'inherit',
              transition: 'color 0.1s',
            }}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Content */}
      <div style={{ flex: 1, overflowY: 'auto' }}>

        {/* Pipeline tab — KNOLL's 17 children */}
        {sidebarTab === 'pipeline' && (
          <div style={{ padding: '10px 8px', display: 'flex', flexDirection: 'column', gap: 3 }}>
            {KNOLL.children.map((child) => {
              const isSelected = selectedNodeId === child.id
              return (
                <button
                  key={child.id}
                  onClick={() => setSelectedNode(isSelected ? null : child.id)}
                  style={{
                    width: '100%',
                    textAlign: 'left',
                    padding: '7px 10px',
                    borderRadius: 4,
                    border: `1px solid ${isSelected ? 'rgba(239,68,68,0.45)' : 'transparent'}`,
                    borderLeft: `2px solid ${isSelected ? '#ef4444' : 'rgba(239,68,68,0.3)'}`,
                    background: isSelected ? 'rgba(239,68,68,0.06)' : 'rgba(255,255,255,0.015)',
                    cursor: 'pointer',
                    fontFamily: 'inherit',
                    transition: 'background 0.1s, border-color 0.1s',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 2 }}>
                    <div style={{
                      width: 6, height: 6, borderRadius: '50%',
                      background: statusDot[child.status], flexShrink: 0,
                    }} />
                    <span style={{ fontSize: 11, fontWeight: 600, color: '#e2e8f0', flex: 1, minWidth: 0 }}>
                      {child.name}
                    </span>
                  </div>
                  <div style={{ fontSize: 9, color: 'rgba(239,68,68,0.55)', textTransform: 'uppercase', letterSpacing: '0.12em' }}>
                    {child.role}
                  </div>
                </button>
              )
            })}
          </div>
        )}

        {/* Tools tab */}
        {sidebarTab === 'tools' && (
          <div style={{ padding: '12px 10px' }}>
            <div style={{ fontSize: 9, color: 'rgba(239,68,68,0.6)', textTransform: 'uppercase', letterSpacing: '0.15em', marginBottom: 10 }}>
              KNOLL Core
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 5, marginBottom: 14 }}>
              {KNOLL.tools.map((t) => (
                <span key={t} style={{
                  fontSize: 9,
                  padding: '3px 7px',
                  borderRadius: 4,
                  background: 'rgba(239,68,68,0.08)',
                  border: '1px solid rgba(239,68,68,0.2)',
                  color: 'rgba(239,68,68,0.8)',
                }}>
                  {t}
                </span>
              ))}
            </div>
            <div style={{ fontSize: 9, color: 'rgba(239,68,68,0.35)', textTransform: 'uppercase', letterSpacing: '0.15em', marginBottom: 8 }}>
              Pipeline Tools
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
              {Array.from(new Set(KNOLL.children.flatMap(c => c.tools))).map((t) => (
                <span key={t} style={{
                  fontSize: 9,
                  padding: '2px 6px',
                  borderRadius: 3,
                  background: 'rgba(255,255,255,0.03)',
                  border: '1px solid rgba(255,255,255,0.06)',
                  color: '#475569',
                }}>
                  {t}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Docs tab */}
        {sidebarTab === 'docs' && (
          <div style={{ padding: 16, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '80%' }}>
            <p style={{ fontSize: 11, color: '#334155', textAlign: 'center', lineHeight: 1.6 }}>
              Documents surface here when connected to Supabase.
            </p>
          </div>
        )}

        {/* Repos tab */}
        {sidebarTab === 'repos' && (
          <div style={{ padding: '10px 8px', display: 'flex', flexDirection: 'column', gap: 4 }}>
            {REPO_LIST.map((r) => (
              <div key={r.name} style={{
                padding: '7px 10px',
                borderRadius: 5,
                background: 'rgba(255,255,255,0.02)',
                border: '1px solid rgba(255,255,255,0.04)',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span style={{ fontSize: 10, color: '#cbd5e1', flex: 1, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {r.name}
                  </span>
                  <span style={{
                    fontSize: 8,
                    padding: '2px 6px',
                    borderRadius: 10,
                    background: repoStatusBg(r.status),
                    color: repoStatusColor(r.status),
                    flexShrink: 0,
                    textTransform: 'uppercase',
                    letterSpacing: '0.1em',
                  }}>
                    {r.status}
                  </span>
                </div>
                <div style={{ fontSize: 9, color: '#1e293b', marginTop: 2 }}>{r.desc}</div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
