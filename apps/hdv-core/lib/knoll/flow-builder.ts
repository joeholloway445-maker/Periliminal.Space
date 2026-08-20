import type { Node, Edge } from '@xyflow/react'
import { MarkerType } from '@xyflow/react'
import { AGENTS } from './agents'
import type { KnollFlowNodeData, ViewMode } from './types'

const AGENT_POS: Record<string, { x: number; y: number }> = {
  knoll:  { x: 750,  y: 20  },
  hope:   { x: 100,  y: 480 },
  apex:   { x: 1400, y: 480 },
  dream:  { x: -650, y: 480 },
  vision: { x: 2050, y: 480 },
}

// KNOLL children: 17 nodes in 4 rows (5+5+5+2), centered at x:750
const KNOLL_CHILD_POS: Record<string, { x: number; y: number }> = {
  'knoll-auth-guard':          { x: 360,  y: 280 },
  'knoll-session-validator':   { x: 555,  y: 280 },
  'knoll-permission-matrix':   { x: 750,  y: 280 },
  'knoll-threat-detector':     { x: 945,  y: 280 },
  'knoll-audit-trail':         { x: 1140, y: 280 },
  'knoll-access-log':          { x: 360,  y: 460 },
  'knoll-vault-keeper':        { x: 555,  y: 460 },
  'knoll-supabase-rls':        { x: 750,  y: 460 },
  'knoll-freeze-gate':         { x: 945,  y: 460 },
  'knoll-redis-cache':         { x: 1140, y: 460 },
  'knoll-legal-gates':         { x: 360,  y: 640 },
  'knoll-tenancy-manager':     { x: 555,  y: 640 },
  'knoll-gvisor-sandbox':      { x: 750,  y: 640 },
  'knoll-observability':       { x: 945,  y: 640 },
  'knoll-prisma-guard':        { x: 1140, y: 640 },
  'knoll-cloudflare-waf':      { x: 653,  y: 820 },
  'knoll-sentry-monitor':      { x: 848,  y: 820 },
}

// HOPE children: 19 nodes in 4 rows (5+5+5+4), centered at x:100
const HOPE_CHILD_POS: Record<string, { x: number; y: number }> = {
  'hope-intent-parser':        { x: -290, y: 730 },
  'hope-persona-manager':      { x: -95,  y: 730 },
  'hope-ui-renderer':          { x: 100,  y: 730 },
  'hope-conversation-buffer':  { x: 295,  y: 730 },
  'hope-context-weaver':       { x: 490,  y: 730 },
  'hope-emotion-engine':       { x: -290, y: 900 },
  'hope-narrative-voice':      { x: -95,  y: 900 },
  'hope-anthropic-client':     { x: 100,  y: 900 },
  'hope-livekit-client':       { x: 295,  y: 900 },
  'hope-posthog-analytics':    { x: 490,  y: 900 },
  'hope-matrix-client':        { x: -290, y: 1070 },
  'hope-nakama-client':        { x: -95,  y: 1070 },
  'hope-monaco-editor':        { x: 100,  y: 1070 },
  'hope-companion-memory':     { x: 295,  y: 1070 },
  'hope-portrait-engine':      { x: 490,  y: 1070 },
  'hope-seo-engine':           { x: -193, y: 1240 },
  'hope-brand-builder':        { x: 3,    y: 1240 },
  'hope-market-research':      { x: 198,  y: 1240 },
  'hope-landing-page-gen':     { x: 393,  y: 1240 },
}

// APEX children: 19 nodes in 4 rows (5+5+5+4), centered at x:1400
const APEX_CHILD_POS: Record<string, { x: number; y: number }> = {
  'apex-task-router':          { x: 1010, y: 730 },
  'apex-agent-spawner':        { x: 1205, y: 730 },
  'apex-tool-registry':        { x: 1400, y: 730 },
  'apex-memory-core':          { x: 1595, y: 730 },
  'apex-security-gate':        { x: 1790, y: 730 },
  'apex-api-bridge':           { x: 1010, y: 900 },
  'apex-resource-allocator':   { x: 1205, y: 900 },
  'apex-mistral-nodes':        { x: 1400, y: 900 },
  'apex-mcp-server':           { x: 1595, y: 900 },
  'apex-kafka-queue':          { x: 1790, y: 900 },
  'apex-model-router':         { x: 1010, y: 1070 },
  'apex-node-matrix':          { x: 1205, y: 1070 },
  'apex-prisma-client':        { x: 1400, y: 1070 },
  'apex-fastify-gateway':      { x: 1595, y: 1070 },
  'apex-byok-router':          { x: 1790, y: 1070 },
  'apex-vercel-deployer':      { x: 1108, y: 1240 },
  'apex-github-actions':       { x: 1303, y: 1240 },
  'apex-cloudflare-edge':      { x: 1498, y: 1240 },
  'apex-docker-orchestrator':  { x: 1693, y: 1240 },
}

// DREAM children: 19 nodes in 4 rows (5+5+5+4), centered at x:-650
const DREAM_CHILD_POS: Record<string, { x: number; y: number }> = {
  'dream-world-builder':       { x: -1040, y: 730 },
  'dream-scene-composer':      { x: -845,  y: 730 },
  'dream-entity-generator':    { x: -650,  y: 730 },
  'dream-physics-simulator':   { x: -455,  y: 730 },
  'dream-chaos-seed':          { x: -260,  y: 730 },
  'dream-narrative-forge':     { x: -1040, y: 900 },
  'dream-asset-synthesizer':   { x: -845,  y: 900 },
  'dream-google-ai-studio':    { x: -650,  y: 900 },
  'dream-colab-image':         { x: -455,  y: 900 },
  'dream-colab-video':         { x: -260,  y: 900 },
  'dream-kokoro-tts':          { x: -1040, y: 1070 },
  'dream-ollama-local':        { x: -845,  y: 1070 },
  'dream-vllm-server':         { x: -650,  y: 1070 },
  'dream-phaser-engine':       { x: -455,  y: 1070 },
  'dream-threejs-3d':          { x: -260,  y: 1070 },
  'dream-elevenlabs':          { x: -943,  y: 1240 },
  'dream-runway-ml':           { x: -748,  y: 1240 },
  'dream-figma-api':           { x: -553,  y: 1240 },
  'dream-canva-api':           { x: -358,  y: 1240 },
}

// VISION children: 25 nodes in 5 rows (5+5+5+5+5), centered at x:2050
const VISION_CHILD_POS: Record<string, { x: number; y: number }> = {
  'vision-task-executor':      { x: 1660, y: 730 },
  'vision-payment-processor':  { x: 1855, y: 730 },
  'vision-automation-runner':  { x: 2050, y: 730 },
  'vision-webhook-manager':    { x: 2245, y: 730 },
  'vision-scheduler-daemon':   { x: 2440, y: 730 },
  'vision-output-streamer':    { x: 1660, y: 900 },
  'vision-audit-logger':       { x: 1855, y: 900 },
  'vision-stripe-connect':     { x: 2050, y: 900 },
  'vision-stripe-identity':    { x: 2245, y: 900 },
  'vision-creator-market':     { x: 2440, y: 900 },
  'vision-livekit-server':     { x: 1660, y: 1070 },
  'vision-nakama-server':      { x: 1855, y: 1070 },
  'vision-billing-meter':      { x: 2050, y: 1070 },
  'vision-sea-scyte-api':      { x: 2245, y: 1070 },
  'vision-resource-monitor':   { x: 2440, y: 1070 },
  'vision-pitch-deck-forge':   { x: 1660, y: 1240 },
  'vision-hubspot-crm':        { x: 1855, y: 1240 },
  'vision-docusign':           { x: 2050, y: 1240 },
  'vision-resend-email':       { x: 2245, y: 1240 },
  'vision-mailchimp':          { x: 2440, y: 1240 },
  'vision-twitter-api':        { x: 1660, y: 1410 },
  'vision-linkedin-api':       { x: 1855, y: 1410 },
  'vision-cal-com':            { x: 2050, y: 1410 },
  'vision-google-ads':         { x: 2245, y: 1410 },
  'vision-airtable':           { x: 2440, y: 1410 },
}

const ALL_CHILD_POS = {
  ...KNOLL_CHILD_POS,
  ...HOPE_CHILD_POS,
  ...APEX_CHILD_POS,
  ...DREAM_CHILD_POS,
  ...VISION_CHILD_POS,
}

function agentToNode(agent: typeof AGENTS[0]): Node<KnollFlowNodeData> {
  return {
    id: agent.id,
    type: agent.class === 'root' ? 'knollRoot' : 'agent',
    position: AGENT_POS[agent.id],
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

function childToNode(child: typeof AGENTS[0]['children'][0], agent: typeof AGENTS[0]): Node<KnollFlowNodeData> {
  return {
    id: child.id,
    type: 'childNode',
    position: ALL_CHILD_POS[child.id] ?? { x: 0, y: 0 },
    data: {
      agentId: child.id,
      label: child.name,
      class: 'child',
      status: child.status,
      primaryColor: agent.primaryColor,
      glowColor: agent.glowColor,
      borderColor: agent.borderColor,
      role: child.role,
      tagline: child.description.slice(0, 60) + '…',
      childCount: 0,
      toolCount: child.tools.length,
    },
  }
}

function makeEdge(source: string, target: string, color: string, animated = true, dashed = false): Edge {
  return {
    id: `${source}->${target}`,
    source,
    target,
    animated,
    style: {
      stroke: color,
      strokeWidth: dashed ? 1.5 : 2,
      strokeDasharray: dashed ? '6 4' : undefined,
    },
    markerEnd: { type: MarkerType.ArrowClosed, color, width: 16, height: 16 },
  }
}

export function buildNodes(viewMode: ViewMode): Node<KnollFlowNodeData>[] {
  const nodes: Node<KnollFlowNodeData>[] = AGENTS.map(agentToNode)
  if (viewMode === 'overview') return nodes
  for (const agent of AGENTS) {
    for (const child of agent.children) {
      nodes.push(childToNode(child, agent))
    }
  }
  return nodes
}

export function buildEdges(viewMode: ViewMode): Edge[] {
  const edges: Edge[] = [
    makeEdge('knoll', 'hope',   '#8b5cf6'),
    makeEdge('knoll', 'apex',   '#06b6d4'),
    makeEdge('knoll', 'dream',  '#d946ef', true, true),
    makeEdge('knoll', 'vision', '#f59e0b', true, true),
    makeEdge('hope',  'apex',   '#a78bfa'),
    makeEdge('apex',  'dream',  '#d946ef', true, true),
    makeEdge('apex',  'vision', '#f59e0b', true, true),
  ]
  if (viewMode === 'overview') return edges
  for (const agent of AGENTS) {
    for (const child of agent.children) {
      edges.push(makeEdge(agent.id, child.id, agent.primaryColor, false))
    }
  }
  return edges
}
