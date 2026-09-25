'use client'

import { useState } from 'react'
import { PHYSICAL_MODS } from '@/lib/game/data/physicalMods'

function ModImage({ id, name, selected }: { id: string; name: string; selected: boolean }) {
  const [visible, setVisible] = useState(true)
  if (!visible) return null
  return (
    <div className="relative w-full h-28 mb-2 rounded overflow-hidden bg-slate-900">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img
        src={`/characters/mods/morph_${id}.jpg`}
        alt={name}
        className="w-full h-full object-cover object-top"
        style={{ borderBottom: selected ? '2px solid #a855f7' : '2px solid #1e1b4b' }}
        onError={() => setVisible(false)}
      />
    </div>
  )
}

export default function StepPhysMod({ value, onChange }: { value: string | null; onChange: (id: string) => void }) {
  return (
    <div>
      <h2 className="font-mono text-lg text-slate-200 mb-1 tracking-wider">CHOOSE YOUR PHYSICAL MOD</h2>
      <p className="font-mono text-xs text-slate-500 mb-4">
        Physical mods are visual augmentations that add minor stat bonuses. 20 options available.
      </p>

      <div className="grid grid-cols-2 gap-2 max-h-[460px] overflow-y-auto pr-1">
        {PHYSICAL_MODS.map((mod) => {
          const selected = value === mod.id
          return (
            <button
              key={mod.id}
              onClick={() => onChange(mod.id)}
              className={`text-left rounded-lg border p-3 transition-all ${
                selected
                  ? 'border-purple-500 bg-purple-950/60'
                  : 'border-slate-800 bg-[#1a1a2e]/40 hover:border-slate-600'
              }`}
            >
              <ModImage id={mod.id} name={mod.name} selected={selected} />
              <div className="font-mono text-xs text-slate-200 mb-1">{mod.name}</div>
              <div className="font-mono text-xs text-slate-500 leading-tight line-clamp-2 mb-1.5">
                {mod.description}
              </div>
              <div className="font-mono text-xs text-cyan-400 mb-0.5">{mod.bonus}</div>
              {mod.drawback && mod.drawback !== 'None' && (
                <div className="font-mono text-xs text-red-500/80 mb-1">{mod.drawback}</div>
              )}
              {Object.keys(mod.statModifier).length > 0 && (
                <div className="flex flex-wrap gap-1">
                  {Object.entries(mod.statModifier).map(([stat, val]) => (
                    <span
                      key={stat}
                      className={`font-mono text-xs px-1 rounded ${
                        (val ?? 0) > 0 ? 'text-green-400 bg-green-950' : 'text-red-400 bg-red-950'
                      }`}
                    >
                      {stat.replace('_', ' ')} {(val ?? 0) > 0 ? '+' : ''}{val}
                    </span>
                  ))}
                </div>
              )}
            </button>
          )
        })}
      </div>
    </div>
  )
}
