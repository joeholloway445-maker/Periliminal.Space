import type { Node, Edge } from '@xyflow/react'
import { MarkerType } from '@xyflow/react'
import { AGENTS } from './agents'
import type { KnollFlowNodeData } from './types'

const KNOLL = AGENTS.find(a => a.id === 'knoll')!
const RED = '#ef4444'

// Pipeline stage x-positions
const SX = [0, 300, 590, 880, 1170, 1460, 1750, 2040, 2330]

// Vertical spread helper
const spread = (count: number, gap = 130) =>
  Array.from({ length: count }, (_, i) => (i - (count - 1) / 2) * gap)

// KNOLL pipeline stages (left → right)
// Stage 0: KNOLL root
// Stage 1: Edge
// Stage 2: Auth
// Stage 3: Authz
// Stage 4: Threat / Compliance
// Stage 5: Isolation
// Stage 6: Monitoring
// Stage 7: Circuit Breaker
// Stage 8: Agent consumers (HOPE, APEX, DREAM, VISION)

const STAGE_POS: Record<string, { x: number; y: number }> = {}

// Stage 1 — Edge (1 node)
STAGE_POS['knoll-cloudflare-waf'] = { x: SX[1], y: 0 }

// Stage 2 — Auth (2 nodes)
const s2 = spread(2)
STAGE_POS['knoll-auth-guard']        = { x: SX[2], y: s2[0] }
STAGE_POS['knoll-session-validator'] = { x: SX[2], y: s2[1] }

// Stage 3 — Authz (3 nodes)
const s3 = spread(3)
STAGE_POS['knoll-permission-matrix'] = { x: SX[3], y: s3[0] }
STAGE_POS['knoll-redis-cache']       = { x: SX[3], y: s3[1] }
STAGE_POS['knoll-supabase-rls']      = { x: SX[3], y: s3[2] }

// Stage 4 — Threat / Compliance (4 nodes)
const s4 = spread(4)
STAGE_POS['knoll-threat-detector']   = { x: SX[4], y: s4[0] }
STAGE_POS['knoll-vault-keeper']      = { x: SX[4], y: s4[1] }
STAGE_POS['knoll-legal-gates']       = { x: SX[4], y: s4[2] }
STAGE_POS['knoll-tenancy-manager']   = { x: SX[4], y: s4[3] }

// Stage 5 — Isolation (3 nodes)
const s5 = spread(3)
STAGE_POS['knoll-prisma-guard']      = { x: SX[5], y: s5[0] }
STAGE_POS['knoll-gvisor-sandbox']    = { x: SX[5], y: s5[1] }
STAGE_POS['knoll-audit-trail']       = { x: SX[5], y: s5[2] }

// Stage 6 — Monitoring (3 nodes)
const s6 = spread(3)
STAGE_POS['knoll-observability']     = { x: SX[6], y: s6[0] }
STAGE_POS['knoll-sentry-monitor']    = { x: SX[6], y: s6[1] }
STAGE_POS['knoll-access-log']        = { x: SX[6], y: s6[2] }

// Stage 7 — Circuit Breaker (1 node)
STAGE_POS['knoll-freeze-gate']       = { x: SX[7], y: 0 }

// Stage 8 — Agent consumers (4 nodes)
const s8 = spread(4, 120)
const AGENT_DEST_POS: Record<string, { x: number; y: number }> = {
  hope:   { x: SX[8], y: s8[0] },
  apex:   { x: SX[8], y: s8[1] },
  dream:  { x: SX[8], y: s8[2] },
  vision: { x: SX[8], y: s8[3] },
}

function knollChildToNode(child: typeof KNOLL['children'][0]): Node<KnollFlowNodeData> {
  return {
    id: child.id,
    type: 'pipelineNode',
    position: STAGE_POS[child.id] ?? { x: 0, y: 0 },
    data: {
      agentId: child.id,
      label: child.name,
      class: 'child',
      status: child.status,
      primaryColor: RED,
      glowColor: 'rgba(239,68,68,0.3)',
      borderColor: RED,
      role: child.role,
      tagline: child.description,
      childCount: 0,
      toolCount: child.tools.length,
    },
  }
}

function agentDestNode(agent: typeof AGENTS[0]): Node<KnollFlowNodeData> {
  return {
    id: agent.id,
    type: 'agentDest',
    position: AGENT_DEST_POS[agent.id] ?? { x: 2330, y: 0 },
    data: {
      agentId: agent.id,
      label: agent.name,
      class: agent.class,
      status: agent.status,
      primaryColor: agent.primaryColor,
      glowColor: agent.glowColor,
      borderColor: agent.borderColor,
      role: agent.role,
      tagline: agent.tagline,
      childCount: agent.children.length,
      toolCount: agent.tools.length,
    },
  }
}

function edge(source: string, target: string, animated = false): Edge {
  return {
    id: `${source}->${target}`,
    source,
    target,
    animated,
    type: 'smoothstep',
    style: { stroke: 'rgba(239,68,68,0.35)', strokeWidth: 1.5 },
    markerEnd: { type: MarkerType.ArrowClosed, color: 'rgba(239,68,68,0.5)', width: 14, height: 14 },
  }
}

export function buildNodes(): Node<KnollFlowNodeData>[] {
  // KNOLL root
  const root: Node<KnollFlowNodeData> = {
    id: 'knoll',
    type: 'knollRoot',
    position: { x: SX[0], y: 0 },
    data: {
      agentId: 'knoll',
      label: 'KNOLL',
      class: 'root',
      status: KNOLL.status,
      primaryColor: RED,
      glowColor: 'rgba(239,68,68,0.4)',
      borderColor: RED,
      role: KNOLL.role,
      tagline: KNOLL.tagline,
      childCount: KNOLL.children.length,
      toolCount: KNOLL.tools.length,
    },
  }

  const children = KNOLL.children.map(knollChildToNode)
  const dests = AGENTS.filter(a => a.id !== 'knoll').map(agentDestNode)

  return [root, ...children, ...dests]
}

export function buildEdges(): Edge[] {
  return [
    // KNOLL → edge layer
    edge('knoll', 'knoll-cloudflare-waf'),

    // Edge → auth
    edge('knoll-cloudflare-waf', 'knoll-auth-guard'),
    edge('knoll-cloudflare-waf', 'knoll-session-validator'),

    // Auth → authz
    edge('knoll-auth-guard',        'knoll-permission-matrix'),
    edge('knoll-session-validator', 'knoll-redis-cache'),
    edge('knoll-session-validator', 'knoll-supabase-rls'),

    // Authz → threat/compliance
    edge('knoll-permission-matrix', 'knoll-threat-detector'),
    edge('knoll-redis-cache',       'knoll-vault-keeper'),
    edge('knoll-supabase-rls',      'knoll-legal-gates'),
    edge('knoll-supabase-rls',      'knoll-tenancy-manager'),

    // Threat/compliance → isolation
    edge('knoll-threat-detector', 'knoll-prisma-guard'),
    edge('knoll-vault-keeper',    'knoll-gvisor-sandbox'),
    edge('knoll-legal-gates',     'knoll-audit-trail'),
    edge('knoll-tenancy-manager', 'knoll-gvisor-sandbox'),

    // Isolation → monitoring
    edge('knoll-prisma-guard',   'knoll-observability'),
    edge('knoll-gvisor-sandbox', 'knoll-sentry-monitor'),
    edge('knoll-audit-trail',    'knoll-access-log'),

    // Monitoring → circuit breaker (animated — live flow)
    edge('knoll-observability',  'knoll-freeze-gate', true),
    edge('knoll-sentry-monitor', 'knoll-freeze-gate', true),
    edge('knoll-access-log',     'knoll-freeze-gate', true),

    // Circuit breaker → agent consumers
    edge('knoll-freeze-gate', 'hope',   true),
    edge('knoll-freeze-gate', 'apex',   true),
    edge('knoll-freeze-gate', 'dream',  true),
    edge('knoll-freeze-gate', 'vision', true),
  ]
}
