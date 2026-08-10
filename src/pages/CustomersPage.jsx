import React, { useState } from 'react'
import { useApp } from '../context/AppContext'
import {
  ini,
  clr,
  fmtD,
  t12,
  bc
} from '../utils/helpers'
import { supabase } from '../supabase'

export default function CustomersPage({ onAddCust, onEditCust }) {
const {
  customers,
  bookings,
  boxes,
  setCustomers,
  showToast
} = useApp()
  const [search, setSearch] = useState('')
  const [selectedCustomer, setSelectedCustomer] =
  useState(null)

 const list = customers
  .filter(
    c =>
      c.name
        .toLowerCase()
        .includes(search.toLowerCase()) ||
      c.phone.includes(search)
  )
  .sort((a, b) => b.cnt - a.cnt)

const customerBookings = selectedCustomer
  ? bookings
      .filter(
        b => b.phone === selectedCustomer.phone
      )
      .sort(
        (a,b)=>
          b.date.localeCompare(a.date)
      )
  : []

const revenue = customerBookings.reduce(
  (sum, b) => sum + (b.amount || 0),
  0
)

const totalHours = customerBookings.reduce(
  (sum, b) => {

    const fromMins =
      Number(b.from.split(':')[0]) * 60 +
      Number(b.from.split(':')[1])

    const toMins =
      Number(b.to.split(':')[0]) * 60 +
      Number(b.to.split(':')[1])

    return sum + ((toMins - fromMins) / 60)

  },
  0
)
const boxCount = {}

customerBookings.forEach(b => {
  boxCount[b.box_id] =
    (boxCount[b.box_id] || 0) + 1
})

const favBoxId =
  Object.keys(boxCount).sort(
    (a, b) => boxCount[b] - boxCount[a]
  )[0]

  const isVip =
  selectedCustomer?.cnt >= 10

  const waCust = (id) => {
    const c = customers.find(x => x.id === id)
    if (!c) return
    const msg = encodeURIComponent(`Hello ${c.name},\n\n🏏 This is HITZONE Box Cricket.\n\nThank you! For bookings: +91 98765 43210\n\n_HITZONE Admin_`)
    window.open(`https://wa.me/91${c.phone.replace(/\D/g,'')}?text=${msg}`, '_blank')
  }

  const delCust = async (id) => {
    const cust = customers.find(
  c => c.id === id
)

const bookingCount = bookings.filter(
  b => b.phone === cust.phone
).length

if (bookingCount > 0) {

  showToast(
    `Customer has ${bookingCount} bookings. Delete bookings first.`,
    'e'
  )

  return
}

  if (!window.confirm('Delete this customer?')) return

  const { error } = await supabase
    .from('customers')
    .delete()
    .eq('id', id)

  if (error) {
    console.error(error)
    showToast('Delete Failed', 'e')
    return
  }

  const updated = customers.filter(c => c.id !== id)

  setCustomers(updated)

  localStorage.setItem(
    'hz_c',
    JSON.stringify(updated)
  )

  showToast('Deleted ✅', 's')
}

  return (
    <div className="page">
      <div className="ph">
        <div><div className="ph-title">Customers</div></div>
       <div
  style={{
    display: 'flex',
    width: '100%',
    justifyContent: 'flex-end'
  }}
>
  <button
    className="btn btn-p"
    onClick={onAddCust}
  >
    👤 Add Customer
  </button>
</div>
      </div>
      <div className="fbar">
        <div style={{display:'flex',alignItems:'center',gap:'8px',background:'var(--bg)',border:'1.5px solid var(--bdr)',borderRadius:'var(--r)',padding:'8px 14px',width:'100%',maxWidth:'380px',flex:1,minWidth:0,boxSizing:'border-box'}}>
          <span style={{color:'var(--tx3)'}}>🔍</span>
          <input type="text" placeholder="Search name or phone..." value={search} onChange={e => setSearch(e.target.value)}
            style={{border:'none',background:'none',outline:'none',fontSize:'14px',color:'var(--tx)',width:'100%',fontFamily:"'Outfit',sans-serif"}}/>
        </div>
      </div>
      <div className="cg">
        {list.length ? list.map(c => (
          <div
  key={c.id}
  className="cc"
  onClick={() => setSelectedCustomer(c)}
  style={{ cursor: 'pointer' }}
>
            <div className="av" style={{background:clr(c.id)+'22',color:clr(c.id),width:'44px',height:'44px',fontSize:'14px',borderRadius:'50%',marginBottom:'10px'}}>{ini(c.name)}</div>
            <div className="cc-name">{c.name}</div>
            <div style={{fontSize:'13px',color:'var(--tx2)',marginTop:'5px'}}>📱 {c.phone}</div>
            {c.notes && <div style={{fontSize:'12px',color:'var(--tx3)',marginTop:'4px'}}>📝 {c.notes}</div>}
            <div className="cc-stats">

  <div className="cs">
    <div
  className="csv"
  style={{color:'var(--blue)'}}
>
  {c.cnt}
</div>

<div className="csl">
  Lifetime
</div>
  </div>

  <div className="cs">
    <div
      className="csv"
      style={{color:'green'}}
    >
      {c.active_count}
    </div>

    <div className="csl">
      Active
    </div>
  </div>

  <div className="cs">
    <div
      className="csv"
      style={{fontSize:'12px'}}
    >
      {c.last}
    </div>

    <div className="csl">
      Last Visit
    </div>
  </div>
            <div
  style={{
    width: "100%",
    display: "flex",
    justifyContent: "flex-end",
    gap: "8px",
    marginTop: "15px",
    paddingTop: "12px",
    borderTop: "1px solid var(--bdr)"
  }}
>
  <button
    className="ab wa"
    onClick={(e) => {
      e.stopPropagation();
      waCust(c.id);
    }}
  >
    💬
  </button>

  <button
    className="ab edit"
    onClick={(e) => {
      e.stopPropagation();
      onEditCust(c.id);
    }}
  >
    ✏️
  </button>

  <button
    className="ab del"
    onClick={(e) => {
      e.stopPropagation();
      delCust(c.id);
    }}
  >
    🗑️
  </button>
</div>
            </div>
          </div>
        )) : <div style={{textAlign:'center',color:'var(--tx3)',padding:'40px',gridColumn:'1/-1',fontSize:'14px'}}>No customers found</div>}
      </div>
      {selectedCustomer && (

<div
  className="mb open"
  onClick={() => setSelectedCustomer(null)}
>

<div
  className="modal"
  onClick={e => e.stopPropagation()}
>

<div className="mh">

<span className="mt">
Customer Profile
</span>

<button
  className="mc"
  onClick={() =>
    setSelectedCustomer(null)
  }
>
✕
</button>

</div>

<h2>
  {selectedCustomer.name}

  {isVip && (
    <span
      style={{
        color: 'gold',
        marginLeft: '10px',
        fontSize: '18px'
      }}
    >
      👑 VIP
    </span>
  )}
</h2>

<p>
📱 {selectedCustomer.phone}
</p>

<p>
🏏 Lifetime Bookings:
{' '}
{selectedCustomer.cnt}
</p>

<p>
✅ Active Bookings:
{' '}
{selectedCustomer.active_count}
</p>

<p>
💰 Revenue:
₹{revenue}
</p>

<p>
⏱ Total Hours:
{' '}
{totalHours}
</p>

<p>
🥇 Favourite Box:
{
boxes.find(
  b => b.id === favBoxId
)?.name || '-'
}
</p>

<hr />

<h3>
Booking History
</h3>

{customerBookings.map(b => (

<div
  key={b.id}
  className="bi"
>

<div className="bi-info">

<div className="bi-name">
{fmtD(b.date)}
</div>

<div className="bi-sub">

{
boxes.find(
x => x.id === b.box_id
)?.name
}

{' • '}

{t12(b.from)}
-
{t12(b.to)}

</div>

</div>

<span
className={`badge ${bc(b.status)}`}
>
{b.status}
</span>

</div>

))}

</div>

</div>

)}
    </div>
  )
}