import { useState } from 'react';
import { supabase, Order } from '@/lib/supabase';
import { Truck, Search, Package2, RotateCcw, CheckCircle2, Building2 } from 'lucide-react';

interface CompanyStat {
  company: string;
  total: number;
  delivered: number;
  returned: number;
  cancelled: number;
  successRate: number;
}

export default function CourierHistoryPage() {
  const [phone, setPhone] = useState('');
  const [orders, setOrders] = useState<(Order & { customers?: { name: string; phone: string } })[]>([]);
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);

  async function search() {
    if (!phone.trim()) return;
    setLoading(true);
    setSearched(true);
    const { data: customers } = await supabase.from('customers').select('id').ilike('phone', `%${phone.trim()}%`);
    const ids = (customers ?? []).map((c: { id: string }) => c.id);
    if (ids.length === 0) {
      setOrders([]);
      setLoading(false);
      return;
    }
    const { data } = await supabase
      .from('orders')
      .select('*, customers(name, phone), order_items(*)')
      .in('customer_id', ids)
      .order('created_at', { ascending: false });
    setOrders((data ?? []) as (Order & { customers?: { name: string; phone: string } })[]);
    setLoading(false);
  }

  const delivered = orders.filter(o => o.status === 'delivered').length;
  const returned  = orders.filter(o => o.status === 'returned').length;
  const total     = orders.length;
  const successRate = total > 0 ? Math.round((delivered / total) * 100) : 0;
  const returnRate  = total > 0 ? Math.round((returned / total) * 100) : 0;

  // Company-wise breakdown
  const companyMap: Record<string, CompanyStat> = {};
  orders.forEach(o => {
    const company = o.courier_company || o.courier_name || 'Unassigned';
    if (!companyMap[company]) companyMap[company] = { company, total: 0, delivered: 0, returned: 0, cancelled: 0, successRate: 0 };
    companyMap[company].total += 1;
    if (o.status === 'delivered') companyMap[company].delivered += 1;
    if (o.status === 'returned')  companyMap[company].returned += 1;
    if (o.status === 'cancelled')  companyMap[company].cancelled += 1;
  });
  const companyStats = Object.values(companyMap).map(c => {
    c.successRate = c.total > 0 ? Math.round((c.delivered / c.total) * 100) : 0;
    return c;
  }).sort((a, b) => b.total - a.total);

  // Overall average success/cancel ratio
  const overallSuccess = companyStats.length > 0 ? Math.round(companyStats.reduce((s, c) => s + c.successRate, 0) / companyStats.length) : 0;
  const overallCancel  = 100 - overallSuccess;

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Courier History</h1>
        <p className="text-slate-400 text-sm mt-1">Search by phone to view courier history across all companies</p>
      </div>

      <div className="flex gap-3">
        <div className="relative flex-1">
          <Truck className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 w-4 h-4" />
          <input
            type="text"
            value={phone}
            onChange={e => setPhone(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && search()}
            placeholder="Enter phone number..."
            className="w-full pl-11 pr-4 py-3 bg-slate-900 border border-white/10 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/50"
          />
        </div>
        <button onClick={search} disabled={loading || !phone.trim()} className="px-6 py-3 bg-emerald-500 hover:bg-emerald-400 disabled:opacity-50 text-white font-medium rounded-xl transition-colors">
          {loading ? '...' : 'Search'}
        </button>
      </div>

      {searched && !loading && orders.length > 0 && (
        <>
          {/* Overall stats */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="bg-slate-900 border border-white/5 rounded-2xl p-5">
              <p className="text-slate-400 text-sm">Total Orders</p>
              <p className="text-2xl font-bold text-white mt-1">{total}</p>
            </div>
            <div className="bg-slate-900 border border-white/5 rounded-2xl p-5">
              <p className="text-slate-400 text-sm">Delivered</p>
              <p className="text-2xl font-bold text-blue-400 mt-1">{delivered}</p>
            </div>
            <div className="bg-slate-900 border border-white/5 rounded-2xl p-5">
              <p className="text-slate-400 text-sm">Returned</p>
              <p className="text-2xl font-bold text-red-400 mt-1">{returned}</p>
            </div>
            <div className="bg-slate-900 border border-white/5 rounded-2xl p-5">
              <p className="text-slate-400 text-sm">Success Rate</p>
              <p className="text-2xl font-bold text-emerald-400 mt-1">{successRate}%</p>
              <p className="text-slate-500 text-xs mt-0.5">Return: {returnRate}%</p>
            </div>
          </div>

          {/* Company-wise breakdown */}
          {companyStats.length > 0 && (
            <div>
              <h2 className="text-white font-semibold text-lg mb-3 flex items-center gap-2">
                <Building2 className="w-5 h-5 text-emerald-400" /> Company-wise Breakdown
              </h2>
              <div className="bg-slate-900 border border-white/5 rounded-2xl overflow-hidden">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-white/5 bg-slate-800/30">
                      <th className="text-left text-slate-400 text-xs font-medium px-5 py-3">Courier Company</th>
                      <th className="text-right text-slate-400 text-xs font-medium px-5 py-3">Total</th>
                      <th className="text-right text-slate-400 text-xs font-medium px-5 py-3">Delivered</th>
                      <th className="text-right text-slate-400 text-xs font-medium px-5 py-3">Returned</th>
                      <th className="text-right text-slate-400 text-xs font-medium px-5 py-3">Success %</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/5">
                    {companyStats.map(c => (
                      <tr key={c.company} className="hover:bg-white/2 transition-colors">
                        <td className="px-5 py-3 text-white text-sm font-medium">{c.company}</td>
                        <td className="px-5 py-3 text-slate-300 text-sm text-right">{c.total}</td>
                        <td className="px-5 py-3 text-blue-400 text-sm text-right">{c.delivered}</td>
                        <td className="px-5 py-3 text-red-400 text-sm text-right">{c.returned}</td>
                        <td className="px-5 py-3 text-emerald-400 text-sm text-right font-medium">{c.successRate}%</td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot>
                    <tr className="border-t-2 border-emerald-500/20 bg-emerald-500/5">
                      <td className="px-5 py-3 text-emerald-400 text-sm font-bold">OVERALL AVERAGE</td>
                      <td className="px-5 py-3 text-white text-sm text-right font-bold">{total}</td>
                      <td className="px-5 py-3 text-white text-sm text-right font-bold">{delivered}</td>
                      <td className="px-5 py-3 text-white text-sm text-right font-bold">{returned}</td>
                      <td className="px-5 py-3 text-emerald-400 text-sm text-right font-bold">
                        {overallSuccess}% success · {overallCancel}% cancel
                      </td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            </div>
          )}
        </>
      )}

      {/* Order list */}
      {searched && (
        loading ? (
          <div className="flex items-center justify-center h-32">
            <div className="w-8 h-8 border-2 border-emerald-500 border-t-transparent rounded-full animate-spin" />
          </div>
        ) : orders.length === 0 ? (
          <div className="bg-slate-900 border border-white/5 rounded-2xl p-12 text-center">
            <Search className="w-10 h-10 text-slate-600 mx-auto mb-3" />
            <p className="text-slate-500">No orders found for this number</p>
          </div>
        ) : (
          <div className="bg-slate-900 border border-white/5 rounded-2xl overflow-hidden">
            <table className="w-full">
              <thead>
                <tr className="border-b border-white/5 bg-slate-800/30">
                  <th className="text-left text-slate-400 text-xs font-medium px-5 py-3">Customer</th>
                  <th className="text-left text-slate-400 text-xs font-medium px-5 py-3">Products</th>
                  <th className="text-right text-slate-400 text-xs font-medium px-5 py-3">Amount</th>
                  <th className="text-left text-slate-400 text-xs font-medium px-5 py-3">Courier</th>
                  <th className="text-left text-slate-400 text-xs font-medium px-5 py-3">Tracking</th>
                  <th className="text-left text-slate-400 text-xs font-medium px-5 py-3">Status</th>
                  <th className="text-left text-slate-400 text-xs font-medium px-5 py-3">Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {orders.map(o => (
                  <tr key={o.id} className="hover:bg-white/2 transition-colors">
                    <td className="px-5 py-3">
                      <p className="text-white text-sm font-medium">{o.customers?.name ?? '-'}</p>
                      <p className="text-slate-500 text-xs">{o.customers?.phone ?? '-'}</p>
                    </td>
                    <td className="px-5 py-3 text-slate-300 text-xs">
                      {(o.order_items ?? []).map((i: { product_name: string }) => i.product_name).join(', ') || '-'}
                    </td>
                    <td className="px-5 py-3 text-emerald-400 text-sm text-right font-medium">৳{o.total_amount.toLocaleString()}</td>
                    <td className="px-5 py-3 text-slate-400 text-sm">{o.courier_company || o.courier_name || '-'}</td>
                    <td className="px-5 py-3 text-slate-400 text-sm font-mono text-xs">{o.courier_tracking_id || '-'}</td>
                    <td className="px-5 py-3">
                      <span className={`flex items-center gap-1 text-xs font-medium ${
                        o.status === 'delivered' ? 'text-blue-400' :
                        o.status === 'returned'  ? 'text-red-400' :
                        o.status === 'confirmed' ? 'text-emerald-400' :
                        'text-slate-400'
                      }`}>
                        {o.status === 'delivered' && <CheckCircle2 className="w-3.5 h-3.5" />}
                        {o.status === 'returned'  && <RotateCcw className="w-3.5 h-3.5" />}
                        {o.status === 'confirmed' && <Package2 className="w-3.5 h-3.5" />}
                        {o.status}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-slate-500 text-xs">{new Date(o.created_at).toLocaleDateString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )
      )}
    </div>
  );
}
