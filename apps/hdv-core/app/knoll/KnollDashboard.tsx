'use client'
import dynamic from 'next/dynamic'
import KnollToolbar from '@/components/knoll/KnollToolbar'
import KnollSidebar from '@/components/knoll/KnollSidebar'
import InspectorPanel from '@/components/knoll/InspectorPanel'
import ActivityFeed from '@/components/knoll/ActivityFeed'

// ReactFlow must be client-side only
const KnollCanvas = dynamic(() => import('@/components/knoll/KnollCanvas'), { ssr: false })

export default function KnollDashboard() {
  return (
    <div
      className="flex flex-col h-screen overflow-hidden"
      style={{ background: '#0a0a14', fontFamily: 'var(--font-geist-mono, monospace)' }}
    >
      {/* Top toolbar */}
      <KnollToolbar />

      {/* Main layout */}
      <div className="flex flex-1 overflow-hidden">

        {/* Left sidebar — agent/tool/doc/repo list */}
        <div className="w-[220px] flex-shrink-0 overflow-hidden">
          <KnollSidebar />
        </div>

        {/* Center — React Flow canvas */}
        <div className="flex-1 relative overflow-hidden">
          <KnollCanvas />
        </div>

        {/* Right panels — inspector + activity */}
        <div
          className="w-[280px] flex-shrink-0 flex flex-col overflow-hidden"
          style={{ borderLeft: '1px solid rgba(239,68,68,0.15)' }}
        >
          {/* Inspector */}
          <div
            className="flex-1 overflow-hidden"
            style={{ borderBottom: '1px solid rgba(239,68,68,0.1)' }}
          >
            <div
              className="px-4 py-2.5 text-[10px] uppercase tracking-widest text-slate-500"
              style={{ borderBottom: '1px solid rgba(239,68,68,0.1)' }}
            >
              Inspector
            </div>
            <div className="h-[calc(100%-36px)] overflow-hidden">
              <InspectorPanel />
            </div>
          </div>

          {/* Activity feed */}
          <div className="h-[260px] overflow-hidden">
            <ActivityFeed />
          </div>
        </div>

      </div>
    </div>
  )
}
