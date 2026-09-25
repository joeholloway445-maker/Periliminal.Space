'use client'
import { Handle, Position } from '@xyflow/react'
import type { NodeProps } from '@xyflow/react'
import type { KnollFlowNodeData } from '@/lib/knoll/types'

const RED = '#ef4444'

const statusColor: Record<string, string> = {
  active:  '#22c55e',
  idle:    '#64748b',
  error:   '#f87171',
  standby: '#f59e0b',
}

const FONT = 'var(--font-geist-mono, "GeistMono", monospace)'

// KNOLL root — the pipeline orchestrator
export function KnollRootNode({ data, selected }: NodeProps<KnollFlowNodeData>) {
  return (
    <div style={{
      width: 200,
      background: '#0d0d0d',
      border: `1.5px solid ${selected ? RED : 'rgba(239,68,68,0.45)'}`,
      borderRadius: 8,
      fontFamily: FONT,
      boxShadow: selected ? `0 0 0 2px ${RED}30, 0 4px 24px rgba(239,68,68,0.2)` : '0 2px 12px rgba(0,0,0,0.6)',
    }}>
      <div style={{
        background: 'rgba(239,68,68,0.1)',
        borderBottom: '1px solid rgba(239,68,68,0.2)',
        padding: '10px 14px',
        borderRadius: '6px 6px 0 0',
        display: 'flex',
        alignItems: 'center',
        gap: 10,
      }}>
        <div style={{
          width: 30, height: 30, borderRadius: 6,
          background: RED,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 15, flexShrink: 0, fontFamily: FONT,
        }}>⚔</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 13, fontWeight: 700, color: '#fff', letterSpacing: '0.12em' }}>{data.label}</div>
          <div style={{ fontSize: 9, color: 'rgba(239,68,68,0.7)', textTransform: 'uppercase', letterSpacing: '0.15em', marginTop: 1 }}>root arbiter</div>
        </div>
        <div style={{ width: 7, height: 7, borderRadius: '50%', background: statusColor[data.status], flexShrink: 0 }} />
      </div>
      <div style={{ padding: '8px 14px 12px' }}>
        <div style={{ fontSize: 10, color: '#475569', lineHeight: 1.4 }}>{data.role}</div>
        <div style={{ marginTop: 6, display: 'flex', gap: 12, fontSize: 9 }}>
          <span style={{ color: 'rgba(239,68,68,0.8)' }}>{data.childCount} nodes</span>
          <span style={{ color: 'rgba(239,68,68,0.8)' }}>{data.toolCount} tools</span>
        </div>
      </div>
      <Handle
        type="source" position={Position.Right}
        style={{ background: RED, width: 12, height: 12, border: '2px solid #0d0d0d', right: -7 }}
      />
    </div>
  )
}

// Pipeline node — KNOLL's 17 security children
export function PipelineNode({ data, selected }: NodeProps<KnollFlowNodeData>) {
  const desc = typeof data.tagline === 'string' ? data.tagline : ''
  const trimmed = desc.length > 60 ? desc.slice(0, 60) + '…' : desc

  return (
    <div style={{
      width: 210,
      background: '#111',
      border: `1px solid ${selected ? RED : '#252525'}`,
      borderLeft: `3px solid ${selected ? RED : 'rgba(239,68,68,0.55)'}`,
      borderRadius: '0 6px 6px 0',
      fontFamily: FONT,
      boxShadow: selected ? `0 0 0 1px ${RED}25, 0 2px 16px rgba(0,0,0,0.5)` : '0 1px 8px rgba(0,0,0,0.4)',
      transition: 'border-color 0.12s',
    }}>
      <div style={{ padding: '9px 12px 10px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3 }}>
          <span style={{ fontSize: 11, fontWeight: 600, color: '#e2e8f0', letterSpacing: '0.04em', flex: 1, minWidth: 0 }}>
            {data.label}
          </span>
          <div style={{ width: 6, height: 6, borderRadius: '50%', background: statusColor[data.status], flexShrink: 0 }} />
        </div>
        <div style={{
          fontSize: 9, fontWeight: 600,
          color: 'rgba(239,68,68,0.65)',
          textTransform: 'uppercase',
          letterSpacing: '0.14em',
          marginBottom: 5,
        }}>{data.role}</div>
        <div style={{ fontSize: 9, color: '#374151', lineHeight: 1.5 }}>{trimmed}</div>
        <div style={{ marginTop: 5, fontSize: 9, color: '#1e293b' }}>{data.toolCount} tools</div>
      </div>
      <Handle type="target" position={Position.Left}
        style={{ background: 'rgba(239,68,68,0.6)', width: 10, height: 10, border: '2px solid #111', left: -5 }} />
      <Handle type="source" position={Position.Right}
        style={{ background: 'rgba(239,68,68,0.6)', width: 10, height: 10, border: '2px solid #111', right: -5 }} />
    </div>
  )
}

// Agent destination node — downstream consumers, de-emphasized
const AGENT_COLORS: Record<string, string> = {
  hope: '#8b5cf6', apex: '#06b6d4', dream: '#d946ef', vision: '#f59e0b',
}

export function AgentDestNode({ data, selected }: NodeProps<KnollFlowNodeData>) {
  const color = AGENT_COLORS[data.agentId as string] ?? '#64748b'
  return (
    <div style={{
      width: 148,
      background: '#0a0a0a',
      border: `1px solid ${selected ? color : color + '35'}`,
      borderRadius: 6,
      fontFamily: FONT,
      opacity: selected ? 1 : 0.75,
      transition: 'opacity 0.15s, border-color 0.15s',
    }}>
      <div style={{
        background: color + '0d',
        borderBottom: `1px solid ${color}25`,
        padding: '6px 11px',
        borderRadius: '5px 5px 0 0',
        display: 'flex',
        alignItems: 'center',
        gap: 6,
      }}>
        <div style={{ fontSize: 11, fontWeight: 700, color, letterSpacing: '0.12em' }}>{data.label}</div>
        <div style={{ marginLeft: 'auto', width: 5, height: 5, borderRadius: '50%', background: statusColor[data.status] }} />
      </div>
      <div style={{ padding: '5px 11px 8px' }}>
        <div style={{ fontSize: 9, color: '#374151' }}>{data.role}</div>
      </div>
      <Handle type="target" position={Position.Left}
        style={{ background: color + '80', width: 10, height: 10, border: '2px solid #0a0a0a', left: -5 }} />
    </div>
  )
}

export const nodeTypes = {
  knollRoot:    KnollRootNode,
  pipelineNode: PipelineNode,
  agentDest:    AgentDestNode,
  agent:        AgentDestNode,
  childNode:    PipelineNode,
}
