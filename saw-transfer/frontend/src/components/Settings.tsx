import React, { useEffect, useState } from 'react'
import { Save, CheckCircle, AlertCircle, Send } from 'lucide-react'
import { settingsApi } from '../api/client'
import type { Settings as SettingsType } from '../types'

export function Settings() {
  const [s, setS] = useState<SettingsType>({ discord_webhook: '', telegram_bot_token: '', telegram_chat_id: '', deal_threshold_pct: '70' })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [testing, setTesting] = useState(false)
  const [saveStatus, setSaveStatus] = useState<'idle'|'ok'|'error'>('idle')
  const [testStatus, setTestStatus] = useState<'idle'|'ok'|'error'>('idle')
  useEffect(() => { settingsApi.get().then(setS).catch(console.error).finally(() => setLoading(false)) }, [])
  const save = async () => { setSaving(true); try { await settingsApi.save(s); setSaveStatus('ok'); setTimeout(() => setSaveStatus('idle'), 3000) } catch { setSaveStatus('error') } finally { setSaving(false) } }
  const test = async () => { setTesting(true); try { await settingsApi.testWebhook(); setTestStatus('ok'); setTimeout(() => setTestStatus('idle'), 5000) } catch { setTestStatus('error') } finally { setTesting(false) } }
  if (loading) return <div style={{ padding: 40, textAlign: 'center', color: 'var(--text-muted)' }}>Loading...</div>
  return (
    <div style={{ maxWidth: 560 }}>
      <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 4 }}>Settings</h2>
      <p style={{ color: 'var(--text-muted)', fontSize: 13, marginBottom: 28 }}>Configure notifications and deal alerts.</p>
      <Section title="Discord" desc="Paste your Discord webhook URL to receive stock alerts.">
        <Field label="Webhook URL" value={s.discord_webhook} onChange={v => setS(x => ({...x, discord_webhook: v}))} placeholder="https://discord.com/api/webhooks/..." />
        <button onClick={test} disabled={testing || !s.discord_webhook} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '8px 14px', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.12)', borderRadius: 8, color: testStatus==='ok'?'#22c55e':testStatus==='error'?'#ef4444':'var(--text-muted)', fontSize: 12, cursor: 'pointer', fontFamily: 'inherit', opacity: !s.discord_webhook?0.4:1, marginTop: 8 }}>
          {testStatus==='ok'?<CheckCircle size={13}/>:testStatus==='error'?<AlertCircle size={13}/>:<Send size={13}/>}{testing?'Sending...':testStatus==='ok'?'Sent!':testStatus==='error'?'Failed':'Test Webhook'}
        </button>
      </Section>
      <Section title="Telegram" desc="Get alerts on Telegram. Create a bot via @BotFather and paste the token below.">
        <Field label="Bot Token" value={s.telegram_bot_token} onChange={v => setS(x => ({...x, telegram_bot_token: v}))} placeholder="123456:ABC-DEF..." />
        <Field label="Chat ID" value={s.telegram_chat_id} onChange={v => setS(x => ({...x, telegram_chat_id: v}))} placeholder="Your Telegram chat ID" />
      </Section>
      <Section title="Deal Alerts" desc="Alert when an item drops by this % or more (for resale detection).">
        <Field label="Discount Threshold %" value={s.deal_threshold_pct} onChange={v => setS(x => ({...x, deal_threshold_pct: v}))} placeholder="70" />
      </Section>
      <div style={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: 12, marginTop: 8 }}>
        {saveStatus !== 'idle' && <span style={{ fontSize: 12, color: saveStatus==='ok'?'#22c55e':'#ef4444' }}>{saveStatus==='ok'?'Saved!':'Failed to save'}</span>}
        <button onClick={save} disabled={saving} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '9px 18px', background: '#6366f1', border: 'none', borderRadius: 8, color: 'white', fontSize: 13, fontWeight: 600, cursor: saving?'not-allowed':'pointer', fontFamily: 'inherit', opacity: saving?0.7:1 }}>
          <Save size={13}/>{saving?'Saving...':'Save Settings'}
        </button>
      </div>
    </div>
  )
}

function Section({ title, desc, children }: { title: string; desc: string; children: React.ReactNode }) {
  return <section style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 12, padding: 20, marginBottom: 16 }}><h3 style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>{title}</h3><p style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 14 }}>{desc}</p>{children}</section>
}

function Field({ label, value, onChange, placeholder }: { label: string; value: string; onChange: (v: string) => void; placeholder: string }) {
  return <div style={{ marginBottom: 10 }}><label style={{ display: 'block', fontSize: 11, fontWeight: 600, color: 'var(--text-muted)', marginBottom: 5, textTransform: 'uppercase', letterSpacing: '0.5px' }}>{label}</label><input value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder} style={{ width: '100%', padding: '10px 12px', background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.12)', borderRadius: 8, color: 'var(--text)', fontSize: 13, outline: 'none', fontFamily: 'inherit' }} /></div>
}
