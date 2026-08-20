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
import { useCallback, useEffect } from 'react'
import { nodeTypes } from './NodeTypes'
import { buildNodes, buildEdges } from '@/lib/knoll/flow-builder'
import { useKnollStore } from '@/lib/knoll/store'
import type { KnollFlowNodeData } from '@/lib/knoll/types'

export default function KnollCanvas() {
  const { viewMode, setSelectedNode } = useKnollStore()
  const [nodes, setNodes, onNodesChange] = useNodesState(buildNodes(viewMode))
  const [edges, setEdges, onEdgesChange] = useEdgesState(buildEdges(viewMode))

  useEffect(() => {
    setNodes(buildNodes(viewMode))
    setEdges(buildEdges(viewMode))
  }, [viewMode, setNodes, setEdges])

  const onNodeClick: NodeMouseHandler<KnollFlowNodeData> = useCallback(
    (_, node) => setSelectedNode(node.id),
    [setSelectedNode]
  )

  const onPaneClick = useCallback(() => setSelectedNode(null), [setSelectedNode])

  return (
    <div className="w-full h-full">
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onNodeClick={onNodeClick}
        onPaneClick={onPaneClick}
        nodeTypes={nodeTypes}
        fitView
        fitViewOptions={{ padding: 0.12 }}
        minZoom={0.05}
        maxZoom={2}
        proOptions={{ hideAttribution: true }}
      >
        <Background
          variant={BackgroundVariant.Dots}
          gap={24}
          size={1}
          color="rgba(139,92,246,0.15)"
        />
        <MiniMap
          style={{
            background: 'rgba(15,15,26,0.85)',
            border: '1px solid rgba(139,92,246,0.3)',
          }}
          nodeColor={(node) => {
            const d = node.data as KnollFlowNodeData
            return d.primaryColor + '88'
          }}
          maskColor="rgba(0,0,0,0.5)"
        />
        <Controls
          style={{
            background: 'rgba(15,15,26,0.85)',
            border: '1px solid rgba(139,92,246,0.3)',
            borderRadius: 8,
          }}
        />
      </ReactFlow>
    </div>
  )
}
