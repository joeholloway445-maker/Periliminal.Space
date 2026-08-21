'use client'
import {
  ReactFlow,
  Background,
  BackgroundVariant,
  MiniMap,
  Controls,
  useNodesState,
  useEdgesState,
  type NodeMouseHandler,
} from '@xyflow/react'
import '@xyflow/react/dist/style.css'
import { useCallback } from 'react'
import { nodeTypes } from './NodeTypes'
import { buildNodes, buildEdges } from '@/lib/knoll/flow-builder'
import { useKnollStore } from '@/lib/knoll/store'
import type { KnollFlowNodeData } from '@/lib/knoll/types'

const INITIAL_NODES = buildNodes()
const INITIAL_EDGES = buildEdges()

export default function KnollCanvas() {
  const { setSelectedNode } = useKnollStore()
  const [nodes, , onNodesChange] = useNodesState(INITIAL_NODES)
  const [edges, , onEdgesChange] = useEdgesState(INITIAL_EDGES)

  const onNodeClick: NodeMouseHandler<KnollFlowNodeData> = useCallback(
    (_, node) => setSelectedNode(node.id),
    [setSelectedNode]
  )

  const onPaneClick = useCallback(() => setSelectedNode(null), [setSelectedNode])

  return (
    <div className="w-full h-full" style={{ background: '#0a0a0a' }}>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onNodeClick={onNodeClick}
        onPaneClick={onPaneClick}
        nodeTypes={nodeTypes}
        fitView
        fitViewOptions={{ padding: 0.08 }}
        minZoom={0.04}
        maxZoom={2}
        proOptions={{ hideAttribution: true }}
      >
        <Background
          variant={BackgroundVariant.Lines}
          gap={40}
          size={1}
          color="rgba(239,68,68,0.04)"
        />
        <MiniMap
          style={{
            background: '#0d0d0d',
            border: '1px solid rgba(239,68,68,0.2)',
            borderRadius: 6,
          }}
          nodeColor={(node) => {
            const d = node.data as KnollFlowNodeData
            return d.primaryColor + '99'
          }}
          maskColor="rgba(0,0,0,0.55)"
        />
        <Controls
          style={{
            background: '#0d0d0d',
            border: '1px solid rgba(239,68,68,0.2)',
            borderRadius: 6,
          }}
        />
      </ReactFlow>
    </div>
  )
}
