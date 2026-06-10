import axios from 'axios'
import type { Product, AlertEvent, Settings, PricePoint, EbayResult, ProfitResult, Sale } from '../types'

const api = axios.create({ baseURL: 'http://localhost:8000', timeout: 15000 })

export const productsApi = {
  list: () => api.get<Product[]>('/products').then(r => r.data),
  add: (url: string, check_interval_seconds: number) => api.post<Product>('/products', { url, check_interval_seconds }).then(r => r.data),
  remove: (id: number) => api.delete(`/products/${id}`),
  update: (id: number, patch: { is_active?: boolean; check_interval_seconds?: number }) => api.patch<Product>(`/products/${id}`, patch).then(r => r.data),
  priceHistory: (id: number) => api.get<PricePoint[]>(`/products/${id}/price-history`).then(r => r.data),
}

export const alertsApi = {
  list: (product_id?: number) => api.get<AlertEvent[]>('/alerts', { params: product_id ? { product_id } : {} }).then(r => r.data),
  exportCsvUrl: () => 'http://localhost:8000/export/csv',
}

export const settingsApi = {
  get: () => api.get<Settings>('/settings').then(r => r.data),
  save: (s: Partial<Settings>) => api.post('/settings', s).then(r => r.data),
  testWebhook: () => api.post('/settings/test-webhook').then(r => r.data),
}

export const profitApi = {
  calculate: (buy_price: number, sell_price: number, weight_grams: number) => api.post<ProfitResult>('/profit/calculate', { buy_price, sell_price, weight_grams }).then(r => r.data),
  ebayLookup: (title: string) => api.get<EbayResult>('/profit/ebay-lookup', { params: { title } }).then(r => r.data),
}

export const salesApi = {
  list: () => api.get<Sale[]>('/sales').then(r => r.data),
  add: (sale: Omit<Sale, 'id' | 'sold_at'>) => api.post('/sales', sale).then(r => r.data),
}

export default api
