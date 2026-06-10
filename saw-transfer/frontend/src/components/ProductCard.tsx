import React from 'react'
import { formatDistanceToNow } from 'date-fns'
import { Trash2, Pause, Play, ExternalLink, Clock, RefreshCw } from 'lucide-react'
import type { Product } from '../types'

const SITE_COLORS: Record<string, string> = { very: '#ff6900', asda: '#78be20', george: '#78be20', pokemon_centre: '#ffcb05', topps: '#e31837', currys: '#003087', argos: '#ed1c24', amazon: '#ff9900', smyths: '#e31837', game: '#e4002b', zavvi: '#e31837', hmv: '#e31837', cex: '#f7941d', john_lewis: '#333', generic: '#6366f1' }
const SITE_LABELS: Record<string, string> = { very: 'Very', asda: 'ASDA', george: 'George', pokemon_centre: 'Pokémon Centre', topps: 'Topps', currys: 'Currys', argos: 'Argos', amazon: 'Amazon', smyths: 'Smyths', game: 'GAME', zavvi: 'Zavvi', hmv: 'HMV', cex: 'CEX', john_lewis: 'John Lewis', generic: 'Generic' }

export function ProductCard({ product: p, onDelete, onToggle }: { product: Product; onDelete: (id: number) => void; onToggle: (id: number, v: boolean) => void }) {
  const color = SITE_COLORS[p.site] || SITE_COLORS.generic
  const label = SITE_LABELS[p.site] || p.site
  const title = p.title || new URL(p.url).hostname
  const statusCfg = { in_stock: { color: '#22c55e', bg: 'rgba(34,197,94,0.15)', label: 'In Stock' }, out_of_stock: { color: '#ef4444', bg: 'rgba(239,68,68,0.15)', label: 'Out of Stock' }, unknown: { color: '#eab308', bg: 'rgba(234,179,8,0.15)', label: 'Unknown' } }[p.status]
  return (
    <div style={{ background: 'rgba(255,255,255,0.04)', border: `1px solid ${p.status === 'in_stock' ? 'rgba(34,197,94,0.3)' : 'rgba(255,255,255,0.08)'}`, borderRadius: 12, overflow: 'hidden', opacity: p.is_active ? 1 : 0.6 }}>
      <div style={{ display: 'flex', gap: 12, padding: 14 }}>
        <div style={{ width: 72, height: 72, flexShrink: 0, borderRadius: 8, background: 'rgba(255,255,255,0.06)', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          {p.image_url ? <img src={p.image_url} alt={title} style={{ width: '100%', height: '100%', objectFit: 'cover' }} onError={e => { (e.target as HTMLImageElement).style.display = 'none' }} /> : <span style={{ fontSize: 24 }}>📦</span>}
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 6, marginBottom: 4 }}>
            <span style={{ fontSize: 10, fontWeight: 700, padding: '1px 7px', borderRadius: 4, background: `${color}20`, color, border: `1px solid ${color}40`, textTransform: 'uppercase', letterSpacing: '0.5px' }}>{label}</span>
            <span style={{ display: 'flex', alignItems: 'center', gap: 5, padding: '2px 8px', borderRadius: 20, background: statusCfg.bg, border: `1px solid ${statusCfg.color}40` }}>
              {p.status === 'in_stock' && <span style={{ width: 6, height: 6, borderRadius: '50%', background: '#22c55e', animation: 'pulse 2s infinite' }} />}
              <span style={{ fontSize: 11, fontWeight: 600, color: statusCfg.color }}>{statusCfg.label}</span>
            </span>
            {!p.ever_in_stock && p.status === 'in_stock' && <span style={{ fontSize: 10, padding: '1px 6px', borderRadius: 4, background: 'rgba(99,102,241,0.2)', color: '#818cf8', fontWeight: 700 }}>NEW DROP</span>}
          </div>
          <h3 style={{ fontSize: 13, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{title}</h3>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, color: 'var(--text-muted)', fontSize: 11, marginTop: 4 }}>
            {p.price && <span style={{ color: '#818cf8', fontWeight: 700, fontSize: 13 }}>{p.price}</span>}
            <span style={{ display: 'flex', alignItems: 'center', gap: 3 }}><RefreshCw size={10} />{p.last_checked ? formatDistanceToNow(new Date(p.last_checked), { addSuffix: true }) : 'Never'}</span>
            <span style={{ display: 'flex', alignItems: 'center', gap: 3 }}><Clock size={10} />every {p.check_interval_seconds < 60 ? `${p.check_interval_seconds}s` : `${Math.round(p.check_interval_seconds/60)}m`}</span>
          </div>
        </div>
      </div>
      <div style={{ display: 'flex', borderTop: '1px solid rgba(255,255,255,0.06)' }}>
        {[['Open', <ExternalLink size={12}/>, 'var(--text-muted)', () => window.open(p.url, '_blank')], [p.is_active ? 'Pause' : 'Resume', p.is_active ? <Pause size={12}/> : <Play size={12}/>, '#eab308', () => onToggle(p.id, !p.is_active)], ['Delete', <Trash2 size={12}/>, '#ef4444', () => { if (confirm(`Remove "${title}"?`)) onDelete(p.id) }]] as [string, React.ReactNode, string, () => void][]}.map(([lbl, icon, color, fn]) => (
          <button key={lbl} onClick={fn} style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5, padding: '8px 4px', background: 'transparent', border: 'none', cursor: 'pointer', color, fontSize: 11, fontWeight: 500, fontFamily: 'inherit' }}>{icon}{lbl}</button>
        ))}
      </div>
    </div>
  )
}
