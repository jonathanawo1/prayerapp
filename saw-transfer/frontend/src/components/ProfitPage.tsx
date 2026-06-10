import React, { useState } from 'react'
import { TrendingUp, Search, Plus, Calculator } from 'lucide-react'
import { profitApi, salesApi } from '../api/client'
import type { ProfitResult, EbayResult, Sale } from '../types'

export function ProfitPage() {
  const [buyPrice, setBuyPrice] = useState('')
  const [sellPrice, setSellPrice] = useState('')
  const [weight, setWeight] = useState('500')
  const [result, setResult] = useState<ProfitResult | null>(null)
  const [ebayQuery, setEbayQuery] = useState('')
  const [ebayResult, setEbayResult] = useState<EbayResult | null>(null)
  const [ebayLoading, setEbayLoading] = useState(false)
  const [sales, setSales] = useState<Sale[]>([])
  const [salesLoaded, setSalesLoaded] = useState(false)
  const [addSaleTitle, setAddSaleTitle] = useState('')
  const [addSaleBuy, setAddSaleBuy] = useState('')
  const [addSaleSell, setAddSaleSell] = useState('')

  const calcProfit = async () => {
    if (!buyPrice || !sellPrice) return
    const r = await profitApi.calculate(parseFloat(buyPrice), parseFloat(sellPrice), parseInt(weight) || 500)
    setResult(r)
  }

  const lookupEbay = async () => {
    if (!ebayQuery.trim()) return
    setEbayLoading(true)
    try { setEbayResult(await profitApi.ebayLookup(ebayQuery)) }
    catch { setEbayResult(null) }
    finally { setEbayLoading(false) }
  }

  const loadSales = async () => {
    if (salesLoaded) return
    setSales(await salesApi.list())
    setSalesLoaded(true)
  }

  const addSale = async () => {
    if (!addSaleTitle || !addSaleBuy || !addSaleSell) return
    const bp = parseFloat(addSaleBuy), sp = parseFloat(addSaleSell)
    const calc = await profitApi.calculate(bp, sp, 500)
    await salesApi.add({ product_title: addSaleTitle, buy_price: `£${bp}`, sell_price: `£${sp}`, fees: `£${calc.ebay_fees}`, postage: `£${calc.postage}`, net_profit: `£${calc.net_profit}` })
    setSales(await salesApi.list())
    setAddSaleTitle(''); setAddSaleBuy(''); setAddSaleSell('')
  }

  const totalProfit = sales.reduce((sum, s) => sum + parseFloat(s.net_profit.replace('£', '') || '0'), 0)

  return (
    <div>
      <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 4 }}>Profit Tools</h2>
      <p style={{ color: 'var(--text-muted)', fontSize: 13, marginBottom: 28 }}>Calculate resale profit and look up eBay sold prices.</p>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 24 }}>
        <Card title="Profit Calculator" icon={<Calculator size={16}/>}>
          <Input label="Buy Price (£)" value={buyPrice} onChange={setBuyPrice} placeholder="19.99" />
          <Input label="Sell Price (£)" value={sellPrice} onChange={setSellPrice} placeholder="45.00" />
          <div style={{ marginBottom: 12 }}>
            <label style={labelStyle}>Weight (grams)</label>
            <select value={weight} onChange={e => setWeight(e.target.value)} style={{ width: '100%', padding: '9px 12px', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.12)', borderRadius: 8, color: 'var(--text)', fontSize: 13, fontFamily: 'inherit' }}>
              {[['100','Large Letter ≤100g'],['250','Large Letter ≤250g'],['750','Small Parcel ≤750g'],['2000','Small Parcel ≤2kg'],['5000','Medium Parcel']].map(([v,l]) => <option key={v} value={v}>{l}</option>)}
            </select>
          </div>
          <button onClick={calcProfit} style={btnStyle('#6366f1')}><Calculator size={14}/>Calculate</button>
          {result && (
            <div style={{ marginTop: 12, padding: 12, background: result.profitable ? 'rgba(34,197,94,0.1)' : 'rgba(239,68,68,0.1)', border: `1px solid ${result.profitable ? 'rgba(34,197,94,0.3)' : 'rgba(239,68,68,0.3)'}`, borderRadius: 8 }}>
              <Row label="Buy Price" value={`£${result.buy_price}`} />
              <Row label="Sell Price" value={`£${result.sell_price}`} />
              <Row label="eBay Fees (12.8%)" value={`-£${result.ebay_fees}`} color="#ef4444" />
              <Row label="Royal Mail Postage" value={`-£${result.postage}`} color="#ef4444" />
              <div style={{ borderTop: '1px solid rgba(255,255,255,0.1)', marginTop: 8, paddingTop: 8 }}>
                <Row label="Net Profit" value={`£${result.net_profit}`} color={result.profitable ? '#22c55e' : '#ef4444'} bold />
              </div>
            </div>
          )}
        </Card>
        <Card title="eBay Price Lookup" icon={<Search size={16}/>}>
          <Input label="Search eBay UK Sold Listings" value={ebayQuery} onChange={setEbayQuery} placeholder="Pokemon Charizard VMAX..." />
          <button onClick={lookupEbay} disabled={ebayLoading} style={btnStyle('#f97316')}><Search size={14}/>{ebayLoading ? 'Searching...' : 'Search eBay Sold'}</button>
          {ebayResult && (
            <div style={{ marginTop: 12, padding: 12, background: 'rgba(249,115,22,0.1)', border: '1px solid rgba(249,115,22,0.3)', borderRadius: 8 }}>
              {ebayResult.avg_sold_price ? (
                <>
                  <Row label="Avg Sold Price" value={`£${ebayResult.avg_sold_price}`} color="#f97316" bold />
                  <Row label="Listings Found" value={`${ebayResult.sold_count}`} />
                  <div style={{ marginTop: 8, fontSize: 11, color: 'var(--text-muted)' }}>Recent: {ebayResult.prices.slice(0,5).map(p => `£${p}`).join(', ')}</div>
                </>
              ) : <p style={{ color: 'var(--text-muted)', fontSize: 12 }}>No sold listings found.</p>}
            </div>
          )}
        </Card>
      </div>
      <Card title="Sales Ledger" icon={<TrendingUp size={16}/>}>
        <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr 1fr auto', gap: 8, marginBottom: 12 }}>
          <input value={addSaleTitle} onChange={e => setAddSaleTitle(e.target.value)} placeholder="Product name" style={inputStyle} />
          <input value={addSaleBuy} onChange={e => setAddSaleBuy(e.target.value)} placeholder="Buy £" style={inputStyle} />
          <input value={addSaleSell} onChange={e => setAddSaleSell(e.target.value)} placeholder="Sell £" style={inputStyle} />
          <button onClick={addSale} style={{ ...btnStyle('#22c55e'), margin: 0, padding: '9px 14px' }}><Plus size={14}/></button>
        </div>
        <button onClick={loadSales} style={{ ...btnStyle('rgba(255,255,255,0.1)'), color: 'var(--text-muted)', marginBottom: 12 }}>Load Sales History</button>
        {salesLoaded && (
          <>
            <div style={{ marginBottom: 8, padding: '8px 12px', background: 'rgba(34,197,94,0.1)', borderRadius: 8, display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>Total Net Profit</span>
              <span style={{ fontWeight: 700, color: totalProfit >= 0 ? '#22c55e' : '#ef4444' }}>£{totalProfit.toFixed(2)}</span>
            </div>
            {sales.map(s => (
              <div key={s.id} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid rgba(255,255,255,0.06)', fontSize: 12 }}>
                <span style={{ flex: 2, color: 'var(--text)' }}>{s.product_title}</span>
                <span style={{ color: 'var(--text-muted)' }}>{s.buy_price} → {s.sell_price}</span>
                <span style={{ fontWeight: 600, color: parseFloat(s.net_profit.replace('£','')) >= 0 ? '#22c55e' : '#ef4444', marginLeft: 16 }}>{s.net_profit}</span>
              </div>
            ))}
          </>
        )}
      </Card>
    </div>
  )
}

const labelStyle: React.CSSProperties = { display: 'block', fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', marginBottom: 5, textTransform: 'uppercase', letterSpacing: '0.5px' }
const inputStyle: React.CSSProperties = { padding: '9px 12px', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.12)', borderRadius: 8, color: 'var(--text)', fontSize: 13, outline: 'none', fontFamily: 'inherit', width: '100%' }
function btnStyle(bg: string): React.CSSProperties { return { display: 'flex', alignItems: 'center', gap: 6, padding: '9px 14px', background: bg, border: 'none', borderRadius: 8, color: 'white', fontSize: 13, fontWeight: 600, cursor: 'pointer', fontFamily: 'inherit', marginBottom: 8, width: '100%', justifyContent: 'center' } }
function Input({ label, value, onChange, placeholder }: { label: string; value: string; onChange: (v: string) => void; placeholder: string }) { return <div style={{ marginBottom: 10 }}><label style={labelStyle}>{label}</label><input value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder} style={{ ...inputStyle, width: '100%' }} /></div> }
function Row({ label, value, color, bold }: { label: string; value: string; color?: string; bold?: boolean }) { return <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 4 }}><span style={{ color: 'var(--text-muted)' }}>{label}</span><span style={{ color: color || 'var(--text)', fontWeight: bold ? 700 : 400 }}>{value}</span></div> }
function Card({ title, icon, children }: { title: string; icon: React.ReactNode; children: React.ReactNode }) { return <div style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 12, padding: 20 }}><div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16 }}>{icon}<h3 style={{ fontSize: 14, fontWeight: 600 }}>{title}</h3></div>{children}</div> }
