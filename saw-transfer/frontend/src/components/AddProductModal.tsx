import React, { useState } from 'react'
import { X, Plus, Link } from 'lucide-react'

const INTERVALS = [{label:'30s',value:30},{label:'1 min',value:60},{label:'5 min',value:300},{label:'15 min',value:900},{label:'30 min',value:1800}]

const SITE_DOMAINS: Record<string, string> = { 'very.co.uk': 'Very', 'asda.com': 'ASDA', 'pokemoncenter.com': 'Pokémon Centre', 'pokemoncentre.com': 'Pokémon Centre', 'topps.com': 'Topps', 'currys.co.uk': 'Currys', 'argos.co.uk': 'Argos', 'amazon.co.uk': 'Amazon UK', 'smythstoys.com': 'Smyths', 'game.co.uk': 'GAME', 'zavvi.com': 'Zavvi', 'hmv.com': 'HMV', 'uk.webuy.com': 'CEX', 'johnlewis.com': 'John Lewis' }

function detectSite(url: string) { for (const [d, n] of Object.entries(SITE_DOMAINS)) { if (url.toLowerCase().includes(d)) return n } return 'Generic' }

export function AddProductModal({ onClose, onAdd }: { onClose: () => void; onAdd: (url: string, i: number) => Promise<void> }) {
  const [url, setUrl] = useState('')
  const [interval, setInterval] = useState(60)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const detected = url ? detectSite(url) : ''
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault(); setError('')
    if (!url.trim()) { setError('Enter a URL'); return }
    try { new URL(url) } catch { setError('Invalid URL'); return }
    setLoading(true)
    try { await onAdd(url.trim(), interval); onClose() }
    catch (err) { setError(err instanceof Error ? err.message : 'Failed') }
    finally { setLoading(false) }
  }
  return (
    <div style={{ position: 'fixed', inset: 0, zIndex: 200, display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(4px)' }} onClick={e => { if (e.target === e.currentTarget) onClose() }}>
      <div style={{ background: '#13131a', border: '1px solid rgba(255,255,255,0.12)', borderRadius: 16, padding: 28, width: '100%', maxWidth: 460 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <h2 style={{ fontSize: 18, fontWeight: 700 }}>Add Product</h2>
          <button onClick={onClose} style={{ background: 'rgba(255,255,255,0.08)', border: 'none', borderRadius: 8, width: 32, height: 32, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: 'var(--text-muted)' }}><X size={16} /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: 16 }}>
            <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.5px' }}>Product URL</label>
            <div style={{ position: 'relative' }}>
              <div style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' }}><Link size={14} /></div>
              <input type="url" value={url} onChange={e => setUrl(e.target.value)} placeholder="https://..." autoFocus style={{ width: '100%', padding: '10px 12px 10px 36px', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.12)', borderRadius: 8, color: 'var(--text)', fontSize: 13, outline: 'none', fontFamily: 'inherit' }} />
            </div>
            {detected && <p style={{ marginTop: 6, fontSize: 11, color: '#818cf8' }}>Detected: <strong>{detected}</strong></p>}
          </div>
          <div style={{ marginBottom: 20 }}>
            <label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.5px' }}>Check Interval</label>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5,1fr)', gap: 6 }}>
              {INTERVALS.map(o => <button key={o.value} type="button" onClick={() => setInterval(o.value)} style={{ padding: '8px 4px', borderRadius: 8, border: `1px solid ${interval===o.value?'#6366f1':'rgba(255,255,255,0.1)'}`, background: interval===o.value?'rgba(99,102,241,0.2)':'rgba(255,255,255,0.04)', color: interval===o.value?'#818cf8':'var(--text-muted)', fontSize: 11, cursor: 'pointer', fontFamily: 'inherit' }}>{o.label}</button>)}
            </div>
          </div>
          {error && <div style={{ marginBottom: 12, padding: '10px 12px', background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)', borderRadius: 8, color: '#ef4444', fontSize: 12 }}>{error}</div>}
          <button type="submit" disabled={loading} style={{ width: '100%', padding: 11, background: loading?'rgba(99,102,241,0.4)':'#6366f1', border: 'none', borderRadius: 8, color: 'white', fontSize: 13, fontWeight: 600, cursor: loading?'not-allowed':'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, fontFamily: 'inherit' }}>
            <Plus size={15} />{loading?'Adding...':'Start Monitoring'}
          </button>
        </form>
      </div>
    </div>
  )
}
