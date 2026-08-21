export type AgentClass = 'root' | 'persistent' | 'ephemeral' | 'child'
export type AgentStatus = 'active' | 'idle' | 'error' | 'standby'
export type ViewMode = 'overview' | 'expanded' | 'full'

export interface ChildNodeDef {
  id: string
  name: string
  role: string
  description: string
  status: AgentStatus
  tools: string[]
}

export interface AgentDef {
  id: string
  name: string
  class: AgentClass
  status: AgentStatus
  primaryColor: string
  glowColor: string
  borderColor: string
  role: string
  tagline: string
  children: ChildNodeDef[]
  tools: string[]
  goals: string[]
}

export interface KnollFlowNodeData extends Record<string, unknown> {
  agentId: string
  label: string
  class: AgentClass
  status: AgentStatus
  primaryColor: string
  glowColor: string
  borderColor: string
  role: string
  tagline: string
  childCount: number
  toolCount: number
}

export interface ActivityEntry {
  id: string
  timestamp: string
  agentId: string
  agentName: string
  action: string
  target: string
  status: AgentStatus
  latencyMs?: number
}

export interface PersonaDef {
  id: string
  agentId: string
  name: string
  voice: string
  traits: string[]
}

export interface DocumentDef {
  id: string
  title: string
  agentId: string
  updatedAt: string
  content: string
}

export interface RepoDef {
  id: string
  name: string
  url: string
  agentId: string
  status: 'active' | 'archived' | 'consolidating'
  description: string
}

export interface ToolDef {
  id: string
  name: string
  agentId: string
  category: string
  description: string
}
