'use client'
import { useKnollStore } from '@/lib/knoll/store'
import { AGENTS, getChildNode } from '@/lib/knoll/agents'

const statusColor: Record<string, string> = {
  active:  'text-emerald-400',
  idle:    'text-slate-400',
  error:   'text-red-400',
  standby: 'text-yellow-400',
}

export default function InspectorPanel() {
  const { selectedNodeId } = useKnollStore()

  if (!selectedNodeId) {
    return (
      <div className="flex flex-col items-center justify-center h-full p-6 text-center">
        <div
          className="w-8 h-8 rounded-full mb-3 flex items-center justify-center"
          style={{ background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)' }}
        >
          <div className="w-2 h-2 rounded-full bg-red-400" style={{ boxShadow: '0 0 6px rgba(239,68,68,0.8)' }} />
        </div>
        <p className="text-slate-500 text-xs">Select a node to inspect</p>
      </div>
    )
  }

  const agent = AGENTS.find(a => a.id === selectedNodeId)
  if (agent) {
    return (
      <div className="p-4 overflow-y-auto h-full">
        <div className="mb-4">
          <div className="flex items-center gap-2 mb-1">
            <div
              className="w-2 h-2 rounded-full"
              style={{ background: agent.primaryColor, boxShadow: `0 0 6px ${agent.glowColor}` }}
            />
            <span className="text-[10px] uppercase tracking-widest" style={{ color: agent.primaryColor }}>
              {agent.class}
            </span>
            <span className={`ml-auto text-[10px] font-semibold ${statusColor[agent.status]}`}>
              {agent.status.toUpperCase()}
            </span>
          </div>
          <h2 className="text-xl font-bold text-white tracking-wider">{agent.name}</h2>
          <p className="text-xs text-slate-400 mt-1">{agent.role}</p>
          <p className="text-xs text-slate-500 mt-2 italic">"{agent.tagline}"</p>
        </div>

        <div className="mb-4">
          <h3 className="text-[10px] uppercase tracking-widest text-slate-500 mb-2">Goals</h3>
          {agent.goals.map((g, i) => (
            <div key={i} className="flex items-start gap-2 mb-1.5">
              <span style={{ color: agent.primaryColor }} className="text-xs mt-0.5 flex-shrink-0">→</span>
              <span className="text-xs text-slate-300">{g}</span>
            </div>
          ))}
        </div>

        <div className="mb-4">
          <h3 className="text-[10px] uppercase tracking-widest text-slate-500 mb-2">
            Tools <span style={{ color: agent.primaryColor }}>({agent.tools.length})</span>
          </h3>
          <div className="flex flex-wrap gap-1.5">
            {agent.tools.map((t) => (
              <span
                key={t}
                className="text-[10px] px-2 py-0.5 rounded font-mono"
                style={{
                  background: agent.primaryColor + '15',
                  border: `1px solid ${agent.primaryColor}40`,
                  color: agent.primaryColor + 'cc',
                }}
              >
                {t}
              </span>
            ))}
          </div>
        </div>

        <div>
          <h3 className="text-[10px] uppercase tracking-widest text-slate-500 mb-2">
            Child Nodes <span style={{ color: agent.primaryColor }}>({agent.children.length})</span>
          </h3>
          {agent.children.map((c) => (
            <div
              key={c.id}
              className="mb-1.5 px-2.5 py-2 rounded-lg"
              style={{ background: 'rgba(255,255,255,0.03)', border: `1px solid ${agent.borderColor}20` }}
            >
              <div className="flex items-center gap-2">
                <span className="text-xs font-semibold text-slate-200">{c.name}</span>
                <span className={`ml-auto text-[9px] ${statusColor[c.status]}`}>{c.status}</span>
              </div>
              <div className="text-[9px] text-slate-500 mt-0.5">{c.role}</div>
            </div>
          ))}
        </div>
      </div>
    )
  }

  const result = getChildNode(selectedNodeId)
  if (result) {
    const { child, agent } = result
    return (
      <div className="p-4 overflow-y-auto h-full">
        <div className="mb-1 text-[9px] uppercase tracking-widest" style={{ color: agent.primaryColor }}>
          {agent.name} → child node
        </div>
        <div className="flex items-center gap-2 mb-1">
          <h2 className="text-lg font-bold text-white">{child.name}</h2>
          <span className={`ml-auto text-[10px] font-semibold ${statusColor[child.status]}`}>
            {child.status.toUpperCase()}
          </span>
        </div>
        <p className="text-xs text-slate-400 mb-1">{child.role}</p>
        <p className="text-xs text-slate-500 mb-4 leading-relaxed">{child.description}</p>

        <div>
          <h3 className="text-[10px] uppercase tracking-widest text-slate-500 mb-2">Tools</h3>
          <div className="flex flex-wrap gap-1.5">
            {child.tools.map((t) => (
              <span
                key={t}
                className="text-[10px] px-2 py-0.5 rounded font-mono"
                style={{
                  background: agent.primaryColor + '15',
                  border: `1px solid ${agent.primaryColor}40`,
                  color: agent.primaryColor + 'cc',
                }}
              >
                {t}
              </span>
            ))}
          </div>
        </div>
      </div>
    )
  }

  return null
}
