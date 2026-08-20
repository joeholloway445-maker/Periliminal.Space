'use client'
import { Handle, Position } from '@xyflow/react'
import type { NodeProps } from '@xyflow/react'
import type { KnollFlowNodeData } from '@/lib/knoll/types'

const statusDot: Record<string, string> = {
  active:  'bg-emerald-400',
  idle:    'bg-slate-500',
  error:   'bg-red-400',
  standby: 'bg-yellow-400',
}

export function KnollRootNode({ data, selected }: NodeProps<KnollFlowNodeData>) {
  return (
    <div
      className="relative rounded-xl px-6 py-4 w-[180px] select-none"
      style={{
        background: 'rgba(15,15,26,0.92)',
        border: `2px solid ${data.borderColor}`,
        boxShadow: selected
          ? `0 0 0 1px ${data.borderColor}, 0 0 32px ${data.glowColor}, 0 0 64px ${data.glowColor}`
          : `0 0 20px ${data.glowColor}, 0 0 40px rgba(239,68,68,0.15)`,
        backdropFilter: 'blur(12px)',
      }}
    >
      <div
        className="absolute -top-px left-6 right-6 h-[2px] rounded-full"
        style={{ background: `linear-gradient(90deg, transparent, ${data.primaryColor}, transparent)` }}
      />
      <div className="flex items-center gap-2 mb-1">
        <span
          className="text-xs font-bold tracking-[0.2em] uppercase"
          style={{ color: data.primaryColor }}
        >
          ROOT
        </span>
        <span className={`ml-auto w-1.5 h-1.5 rounded-full ${statusDot[data.status]}`} />
      </div>
      <div className="text-lg font-bold text-white tracking-wider">{data.label}</div>
      <div className="text-[10px] text-slate-400 mt-1 leading-tight">{data.role}</div>
      <div className="mt-2 flex gap-3 text-[10px] text-slate-500">
        <span><span style={{ color: data.primaryColor }}>{data.childCount}</span> nodes</span>
        <span><span style={{ color: data.primaryColor }}>{data.toolCount}</span> tools</span>
      </div>
      <Handle type="source" position={Position.Bottom} className="!w-2 !h-2 !border-0" style={{ background: data.primaryColor }} />
    </div>
  )
}

export function AgentNode({ data, selected }: NodeProps<KnollFlowNodeData>) {
  const isEphemeral = data.class === 'ephemeral'
  return (
    <div
      className="relative rounded-xl px-5 py-4 w-[170px] select-none"
      style={{
        background: 'rgba(15,15,26,0.88)',
        border: `1.5px solid ${isEphemeral ? data.borderColor + '88' : data.borderColor}`,
        boxShadow: selected
          ? `0 0 0 1px ${data.borderColor}, 0 0 24px ${data.glowColor}`
          : `0 0 14px ${data.glowColor}`,
        backdropFilter: 'blur(10px)',
      }}
    >
      <div
        className="absolute -top-px left-4 right-4 h-[1.5px]"
        style={{
          background: `linear-gradient(90deg, transparent, ${data.primaryColor}${isEphemeral ? '88' : 'cc'}, transparent)`,
        }}
      />
      <div className="flex items-center gap-2 mb-1">
        <span
          className="text-[10px] font-semibold tracking-[0.15em] uppercase"
          style={{ color: data.primaryColor + (isEphemeral ? 'aa' : '') }}
        >
          {data.class}
        </span>
        <span className={`ml-auto w-1.5 h-1.5 rounded-full ${statusDot[data.status]}`} />
      </div>
      <div className="text-base font-bold text-white tracking-wide">{data.label}</div>
      <div className="text-[10px] text-slate-400 mt-0.5 leading-tight">{data.role}</div>
      <div className="mt-2 flex gap-3 text-[10px] text-slate-500">
        <span><span style={{ color: data.primaryColor }}>{data.childCount}</span> nodes</span>
        <span><span style={{ color: data.primaryColor }}>{data.toolCount}</span> tools</span>
      </div>
      <Handle type="target" position={Position.Top} className="!w-2 !h-2 !border-0" style={{ background: data.primaryColor }} />
      <Handle type="source" position={Position.Bottom} className="!w-2 !h-2 !border-0" style={{ background: data.primaryColor }} />
    </div>
  )
}

export function ChildNode({ data, selected }: NodeProps<KnollFlowNodeData>) {
  return (
    <div
      className="relative rounded-lg px-3 py-2.5 w-[150px] select-none"
      style={{
        background: 'rgba(15,15,26,0.82)',
        border: `1px solid ${selected ? data.borderColor : data.borderColor + '55'}`,
        boxShadow: selected ? `0 0 12px ${data.glowColor}` : 'none',
        backdropFilter: 'blur(8px)',
        transition: 'border-color 0.15s, box-shadow 0.15s',
      }}
    >
      <div className="flex items-center gap-1.5 mb-0.5">
        <div className="text-[11px] font-semibold text-white truncate leading-tight flex-1">{data.label}</div>
        <span className={`w-1.5 h-1.5 rounded-full flex-shrink-0 ${statusDot[data.status]}`} />
      </div>
      <div
        className="text-[9px] font-medium uppercase tracking-widest"
        style={{ color: data.primaryColor + 'cc' }}
      >
        {data.role}
      </div>
      <div className="mt-1 text-[9px] text-slate-500">
        {data.toolCount} tools
      </div>
      <Handle type="target" position={Position.Top} className="!w-1.5 !h-1.5 !border-0" style={{ background: data.primaryColor }} />
    </div>
  )
}

export const nodeTypes = {
  knollRoot: KnollRootNode,
  agent: AgentNode,
  childNode: ChildNode,
}
