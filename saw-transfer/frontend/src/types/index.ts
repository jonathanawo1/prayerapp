export interface Product {
  id: number
  url: string
  site: string
  title: string | null
  image_url: string | null
  price: string | null
  status: 'in_stock' | 'out_of_stock' | 'unknown'
  is_active: boolean
  ever_in_stock: boolean
  check_interval_seconds: number
  last_checked: string | null
  created_at: string
}

export interface AlertEvent {
  id: number
  product_id: number
  event_type: 'in_stock' | 'out_of_stock' | 'price_change' | 'deal' | 'queue'
  old_value: string | null
  new_value: string | null
  notified: boolean
  created_at: string
  product?: Product
}

export interface Settings {
  discord_webhook: string
  telegram_bot_token: string
  telegram_chat_id: string
  deal_threshold_pct: string
}

export interface PricePoint { price: string; recorded_at: string }
export interface EbayResult { avg_sold_price: number | null; sold_count: number; prices: number[] }
export interface ProfitResult { buy_price: number; sell_price: number; ebay_fees: number; postage: number; net_profit: number; profitable: boolean }
export interface Sale { id: number; product_title: string; buy_price: string; sell_price: string; fees: string; postage: string; net_profit: string; sold_at: string }
export type Tab = 'watching' | 'in_stock' | 'alerted'
export type Page = 'dashboard' | 'profit' | 'settings'
