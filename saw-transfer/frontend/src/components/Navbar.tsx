import React from 'react'
import { Eye, Settings as Cog, TrendingUp } from 'lucide-react'
import type { Page } from '../types'

export function Navbar({ currentPage, onNavigate }: { currentPage: Page; onNavigate: (p: Page) => void }) {
  return (
    <nav style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 24px', height: 56, background: 'rgba(255,255,255,0.03)', borderBottom: '1px solid rgba(255,255,255,0.08)', backdropFilter: 'blur(10px)', position: 'sticky', top: 0, zIndex: 100 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{ width: 32, height: 32, background: 'linear-gradient(135deg, #6366f1, #22c55e)', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Eye size={16} color="white" />
        </div>
        <span style={{ fontWeight: 700, fontSize: 16, letterSpacing: '-0.5px' }}>SAW</span>
        <span style={{ color: 'var(--text-muted)', fontSize: 12 }}>Stock Alert Watcher</span>
      </div>
      <div style={{ display: 'flex', gap: 4 }}>
        {([['dashboard', <Eye size={14}/>, 'Dashboard'], ['profit', <TrendingUp size={14}/>, 'Profit'], ['settings', <Cog size={14}/>, 'Settings']] as [Page, React.ReactNode, string][]).map(([p, icon, label]) => (
          <button key={p} onClick={() => onNavigate(p)} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '6px 12px', borderRadius: 6, border: 'none', cursor: 'pointer', fontSize: 13, fontWeight: 500, background: currentPage === p ? 'rgba(99,102,241,0.2)' : 'transparent', color: currentPage === p ? '#818cf8' : 'var(--text-muted)', fontFamily: 'inherit' }}>
            {icon}{label}
          </button>
        ))}
      </div>
    </nav>
  )
}
