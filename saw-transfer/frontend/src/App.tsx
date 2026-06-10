import React, { useState, useCallback } from 'react'
import { Navbar } from './components/Navbar'
import { Dashboard } from './components/Dashboard'
import { ProfitPage } from './components/ProfitPage'
import { Settings } from './components/Settings'
import { useProducts } from './hooks/useProducts'
import { useWebSocket } from './hooks/useWebSocket'
import type { Page } from './types'

export default function App() {
  const [page, setPage] = useState<Page>('dashboard')
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)
  const [queueAlerts, setQueueAlerts] = useState<Array<{ product_id: number; url: string; ts: Date }>>([])

  const { products, loading, addProduct, removeProduct, updateProduct, handleWsUpdate } = useProducts()

  const onQueueDetected = useCallback((data: { product_id: number; url: string }) => {
    setQueueAlerts(prev => [{ ...data, ts: new Date() }, ...prev.slice(0, 9)])
    if (Notification.permission === 'granted') {
      new Notification('SAW: Queue Live!', { body: `Queue detected — open now: ${data.url}` })
    }
  }, [])

  useWebSocket({
    onProductUpdate: (p) => { handleWsUpdate(p); setLastUpdated(new Date()) },
    onQueueDetected,
  })

  return (
    <>
      <Navbar currentPage={page} onNavigate={setPage} />
      {queueAlerts.length > 0 && (
        <div style={{ background: 'rgba(168,85,247,0.15)', borderBottom: '1px solid rgba(168,85,247,0.4)', padding: '10px 24px', display: 'flex', alignItems: 'center', gap: 12 }}>
          <span style={{ color: '#a855f7', fontWeight: 700, fontSize: 13 }}>🟣 QUEUE LIVE</span>
          <a href={queueAlerts[0].url} target="_blank" rel="noreferrer" style={{ color: '#c084fc', fontSize: 12 }}>{queueAlerts[0].url}</a>
          <button onClick={() => setQueueAlerts([])} style={{ marginLeft: 'auto', background: 'none', border: 'none', color: '#94a3b8', cursor: 'pointer', fontSize: 11 }}>Dismiss</button>
        </div>
      )}
      <main style={{ maxWidth: 1200, margin: '0 auto', padding: '32px 24px' }}>
        {page === 'dashboard' && <Dashboard products={products} loading={loading} onAdd={async (url, i) => { await addProduct(url, i); setLastUpdated(new Date()) }} onDelete={removeProduct} onToggle={(id, v) => updateProduct(id, { is_active: v })} lastUpdated={lastUpdated} />}
        {page === 'profit' && <ProfitPage />}
        {page === 'settings' && <Settings />}
      </main>
    </>
  )
}
