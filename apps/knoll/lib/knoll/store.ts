'use client'
import { create } from 'zustand'
import type { ViewMode, ActivityEntry, AgentDef } from './types'

interface KnollStore {
  viewMode: ViewMode
  selectedNodeId: string | null
  sidebarTab: 'pipeline' | 'tools' | 'docs' | 'repos'
  activityFeed: ActivityEntry[]
  setViewMode: (mode: ViewMode) => void
  setSelectedNode: (id: string | null) => void
  setSidebarTab: (tab: KnollStore['sidebarTab']) => void
  pushActivity: (entry: ActivityEntry) => void
}

export const useKnollStore = create<KnollStore>((set) => ({
  viewMode: 'overview',
  selectedNodeId: null,
  sidebarTab: 'pipeline',
  activityFeed: [],

  setViewMode: (mode) => set({ viewMode: mode }),
  setSelectedNode: (id) => set({ selectedNodeId: id }),
  setSidebarTab: (tab) => set({ sidebarTab: tab }),
  pushActivity: (entry) =>
    set((s) => ({
      activityFeed: [entry, ...s.activityFeed].slice(0, 50),
    })),
}))

export type { AgentDef }
