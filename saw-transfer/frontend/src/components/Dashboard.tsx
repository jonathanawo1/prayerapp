import React, { useState } from 'react'
import { Plus, Eye, CheckCircle, Bell, RefreshCw } from 'lucide-react'
import { formatDistanceToNow } from 'date-fns'
import { ProductCard } from './ProductCard'
import { AddProductModal } from './AddProductModal'
import { AlertHistory } from './AlertHistory'
import type { Product, Tab } from '../types'

interface Props { products: Product[]; loading: boolean; onAdd: (url: string, i: number) => Promise<void>; onDelete: (id: number) => void; onToggle: (id: number, v: boolean) => void; lastUpdated: Date | null }

export function Dashboard({ products, loading, onAdd, onDelete, onToggle, lastUpdated }: Props) {
  const [tab, setTab] = useState<Tab>('watching')
  const [showModal, setShowModal] = useState(false)
  const inStock = products.filter(p => p.status === 'in_stock')
  const displayed = tab === 'watching' ? products : tab === 'in_stock' ? inStock : inStock
  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24 }}>
        <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
          <Chip label="Watching" value={products.length} color="#6366f1" />
          <Chip label="In Stock" value={inStock.length} color="#22c55e" />
          {lastUpdated && <span style={{ fontSize: 11, color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: 4 }}><RefreshCw size={10} />Updated {formatDistanceToNow(lastUpdated, { addSuffix: true })}</span>}
        </div>
        <button onClick={() => setShowModal(true)} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '9px 16px', background: '#6366f1', border: 'none', borderRadius: 8, color: 'white', fontSize: 13, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit' }}>
          <Plus size={15} />Add Product
        </button>
      </div>
      <div style={{ display: 'flex', gap: 4, marginBottom: 20, background: 'rgba(255,255,255,0.04)', borderRadius: 10, padding: 4, width: 'fit-content' }}>
        {([['watching', <Eye size={13}/>, 'Watching', products.length], ['in_stock', <CheckCircle size={13}/>, 'In Stock', inStock.length], ['alerted', <Bell size={13}/>, 'Alerts', 0]] as [Tab, React.ReactNode, string, number][]).map(([key, icon, label, count]) => (
          <button key={key} onClick={() => setTab(key)} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '7px 14px', borderRadius: 7, border: 'none', cursor: 'pointer', fontSize: 13, fontWeight: 500, background: tab === key ? 'rgba(255,255,255,0.1)' : 'transparent', color: tab === key ? 'var(--text)' : 'var(--text-muted)', fontFamily: 'inherit' }}>
            {icon}{label}
            <span style={{ fontSize: 11, fontWeight: 700, padding: '1px 6px', borderRadius: 10, background: tab === key ? 'rgba(99,102,241,0.3)' : 'rgba(255,255,255,0.08)', color: tab === key ? '#818cf8' : 'var(--text-muted)' }}>{key === 'alerted' ? '' : count}</span>
          </button>
        ))}
      </div>
      {tab === 'alerted' ? <AlertHistory /> : loading ? (
        <div style={{ textAlign: 'center', padding: 60, color: 'var(--text-muted)' }}><RefreshCw size={24} style={{ animation: 'spin 1s linear infinite' }} /><p style={{ marginTop: 12 }}>Loading...</p></div>
      ) : displayed.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 60, background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, color: 'var(--text-muted)' }}>
          <Eye size={36} style={{ opacity: 0.3, marginBottom: 12 }} /><p>No products yet. Click "Add Product" to start.</p>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: 12 }}>
          {displayed.map(p => <ProductCard key={p.id} product={p} onDelete={onDelete} onToggle={onToggle} />)}
        </div>
      )}
      {showModal && <AddProductModal onClose={() => setShowModal(false)} onAdd={onAdd} />}
    </div>
  )
}

function Chip({ label, value, color }: { label: string; value: number; color: string }) {
  return <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 12px', background: `${color}10`, border: `1px solid ${color}30`, borderRadius: 8 }}><span style={{ fontSize: 18, fontWeight: 700, color }}>{value}</span><span style={{ fontSize: 12, color: 'var(--text-muted)' }}>{label}</span></div>
}
