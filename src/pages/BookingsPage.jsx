import React, { useState } from 'react'
import { useApp } from '../context/AppContext'
import { t12, fmtD, bc, calcH } from '../utils/helpers'
import { TODAY } from '../utils/helpers'
import { supabase } from '../supabase'

export default function BookingsPage({ onNewBooking, onRecurring }) {
  const {
  bookings,
  setBookings,
  customers,
  setCustomers,
  showToast
} = useApp()
  const [filter, setFilter] = useState('all')
  const [dateFilter, setDateFilter] = useState('')

  const delB = async (id) => {

  if (!window.confirm('Delete this booking?')) return
  const deletedBooking =
  bookings.find(b => b.id === id)

 const { data: deleteData, error } = await supabase
  .from('bookings')
  .delete()
  .eq('id', id)
  .select()

console.log("DELETE RESULT:", deleteData)
console.log("DELETE ERROR:", error)

  if (error) {
    console.error(error)
    showToast('Delete Failed', 'e')
    return
  }

  const updated = bookings.filter(b => b.id !== id)

  setBookings(updated)
  setCustomers(prev =>
  prev.map(c =>
    c.phone === deletedBooking.phone
      ? {
          ...c,
          cnt: Math.max(0, (c.cnt || 0) - 1)
        }
      : c
  )
)

  localStorage.setItem
    'hz_b',
    JSON.stringify(updated
  )

 if (bookingToDelete) {

  const { data: customerData } = await supabase
    .from('customers')
    .select('*')
    .eq('phone', bookingToDelete.phone)
    .single()

  if (customerData) {

    const newCount =
      Math.max(
        0,
        (customerData.cnt || 0) - 1
      )

    await supabase
      .from('customers')
      .update({
        cnt: newCount
      })
      .eq('id', customerData.id)

  }

}
  showToast('Deleted ✅', 's')
}

  const waQ = (id) => {
    const b = bookings.find(x => x.id === id)
    if (!b) return
    const msg = encodeURIComponent(`Hello ${b.name},\n\n🏏 *HITZONE Box Cricket*\n\n📅 Date: ${fmtD(b.date)}\n⏰ ${t12(b.from)} – ${t12(b.to)}\n\nSee you at HITZONE! 🏟️`)
    window.open(`https://wa.me/91${b.phone.replace(/\D/g,'')}?text=${msg}`, '_blank')
  }

  let list = [...bookings]
  console.log("FILTER =", filter)
console.log("TOTAL BOOKINGS =", bookings)
  if (filter !== 'all') list = list.filter(b => b.status === filter)
    console.log("FILTERED LIST =", list)
  if (dateFilter) list = list.filter(b => b.date === dateFilter)
  list.sort((a,b) => b.date.localeCompare(a.date) || a.from.localeCompare(b.from))

  return (
    <div className="page">
      <div className="ph">
        <div><div className="ph-title">All Bookings</div></div>
        <div style={{display:'flex',gap:'8px',flexWrap:'wrap'}}>
          <button className="btn btn-s btn-sm" onClick={onRecurring}>🔁 Recurring</button>
          <button className="btn btn-p" onClick={() => onNewBooking()}>➕ New Booking</button>
        </div>
      </div>
      <div className="fbar">
        {['all','confirmed','completed','cancelled'].map(s => (
          <button key={s} className={`chip${filter===s?' active':''}`} onClick={() => setFilter(s)}>
            {s.charAt(0).toUpperCase()+s.slice(1)}
          </button>
        ))}
        <input type="date" className="fi" style={{marginLeft:'auto',width:'auto',padding:'6px 12px',fontSize:'13px',borderRadius:'99px'}}
          value={dateFilter} onChange={e => setDateFilter(e.target.value)}/>
      </div>
      <div className="tw">
        <table>
          <thead>
<tr>
<th>#</th>
<th>Customer</th>
<th>Date</th>
<th>Time</th>
<th>Hrs</th>
<th>Amount</th>
<th>Status</th>
<th>Actions</th>
</tr>
</thead>
          <tbody>
            {list.length ? list.map((b,i) => (
              <tr key={b.id}>
                <td style={{color:'var(--tx3)',fontSize:'12px'}}>{i+1}</td>
                <td><div style={{fontWeight:700}}>{b.name}</div><div style={{fontSize:'12px',color:'var(--tx3)'}}>📱 {b.phone}</div></td>
                <td style={{fontWeight:600}}>{fmtD(b.date)}</td>
                <td style={{fontFamily:"'Space Grotesk',sans-serif",fontWeight:700}}>{t12(b.from)}–{t12(b.to)}</td>
                <td>{calcH(b.from,b.to)}h</td>
                <td style={{fontWeight:700}}>
  ₹{(b.amount||0).toLocaleString('en-IN')}
</td>
<td>
  <span className={`badge ${bc(b.status)}`}>
    {b.status}
  </span>
</td>
                <td>
                  <div className="acts">
                    <button className="ab edit" onClick={() => onNewBooking(b.id)} title="Edit">✏️</button>
                    <button className="ab wa" onClick={() => waQ(b.id)} title="WhatsApp">💬</button>
                    <button className="ab del" onClick={() => delB(b.id)} title="Delete">🗑️</button>
                  </div>
                </td>
              </tr>
            )) : (
              <tr><td colSpan="8" style={{textAlign:'center',padding:'28px',color:'var(--tx3)'}}>No bookings found</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
