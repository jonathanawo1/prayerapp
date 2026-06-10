import React, { useEffect, useState } from 'react'
import { format, formatDistanceToNow } from 'date-fns'
import { Download, Bell, TrendingUp, TrendingDown } from 'lucide-react'
import { alertsApi } from '../api/client'
import type { AlertEvent } from '../types'

export function AlertHistory() {
  const [alerts, setAlerts] = useState<AlertEvent[]>([])
  const [loading, setLoading] = useState(true)
  useEffect(() => { alertsApi.list().then(setAlerts).catch(console.error).finally(() => setLoading(false)) }, [])
  const cfg = {
    in_stock: { label: 'IN STOCK', color: '#22c55e', bg: 'rgba(34,197,94,0.15)', icon: <TrendingUp size={11}/> },
    out_of_stock: { label: 'OUT OF STOCK', color: '#ef4444', bg: 'rgba(239,68,68,0.15)', icon: <TrendingDown size={11}/> },
    price_change: { label: 'PRICE CHANGE', color: '#eab308', bg: 'rgba(234,179,8,0.15)', icon: <Bell size={11}/> },
    deal: { label: 'DEAL', color: '#f97316', bg: 'rgba(249,115,22,0.15)', icon: <TrendingUp size={11}/> },
    queue: { label: 'QUEUE', color: '#a855f7', bg: 'rgba(168,85,247,0.15)', icon: <Bell size={11}/> },
  }
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <div><h2 style={{ fontSize: 16, fontWeight: 700 }}>Alert History</h2><p style={{ color: 'var(--text-muted)', fontSize: 12, marginTop: 2 }}>{alerts.length} events</p></div>
        <button onClick={() => window.open(alertsApi.exportCsvUrl(), '_blank')} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '8px 14px', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.12)', borderRadius: 8, color: 'var(--text-muted)', fontSize: 12, cursor: 'pointer', fontFamily: 'inherit' }}><Download size={13}/>Export CSV</button>
      </div>
      {loading ? <div style={{ textAlign: 'center', padding: 40, color: 'var(--text-muted)' }}>Loading...</div> : alerts.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 60, background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, color: 'var(--text-muted)' }}><Bell size={32} style={{ opacity: 0.3, marginBottom: 12 }}/><p>No alerts yet.</p></div>
      ) : (
        <div style={{ background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead><tr style={{ borderBottom: '1px solid rgba(255,255,255,0.08)' }}>{['Time','Product','Event','Price/Change'].map(h => <th key={h} style={{ padding: '10px 16px', textAlign: 'left', fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>{h}</th>)}</tr></thead>
            <tbody>{alerts.map((a, i) => { const c = cfg[a.event_type] || cfg.price_change; return (
              <tr key={a.id} style={{ borderBottom: i < alerts.length-1 ? '1px solid rgba(255,255,255,0.05)' : 'none' }}>
                <td style={{ padding: '10px 16px', fontSize: 12, color: 'var(--text-muted)' }}><div>{format(new Date(a.created_at), 'MMM d, HH:mm')}</div><div style={{ fontSize: 10, opacity: 0.6 }}>{formatDistanceToNow(new Date(a.created_at), { addSuffix: true })}</div></td>
                <td style={{ padding: '10px 16px', fontSize: 12, maxWidth: 200 }}><div style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{a.product?.title || `#${a.product_id}`}</div></td>
                <td style={{ padding: '10px 16px' }}><span style={{ display: 'inline-flex', alignItems: 'center', gap: 5, padding: '3px 8px', borderRadius: 6, background: c.bg, color: c.color, fontSize: 11, fontWeight: 600 }}>{c.icon}{c.label}</span></td>
                <td style={{ padding: '10px 16px', fontSize: 12 }}>{a.event_type === 'price_change' ? <span><span style={{ color: '#ef4444', textDecoration: 'line-through' }}>{a.old_value}</span>{' → '}<span style={{ color: '#22c55e' }}>{a.new_value}</span></span> : <span style={{ color: 'var(--text-muted)' }}>{a.product?.price || '—'}</span>}</td>
              </tr>
            )})}</tbody>
          </table>
        </div>
      )}
    </div>
  )
}
