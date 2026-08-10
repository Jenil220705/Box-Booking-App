import React from 'react'
import CountUp from 'react-countup'
import { motion } from 'framer-motion'
import { useApp } from '../context/AppContext'
import { TODAY, t12, fmtD, calcH, bc, ini, clr } from '../utils/helpers'
import { supabase } from '../supabase'


export default function Dashboard({ onNewBooking, onRecurring }) {
 const {
  bookings,
  customers,
  recurGroups,
  boxes,
  expenses,
  go,
  cfg
} = useApp() 
  const now = new Date(), h = now.getHours()
  const greet = (h<12?'Good Morning 🌅':h<17?'Good Afternoon ☀️':'Good Evening 🌙')+', Admin'
const todayDate = now.toLocaleDateString("en-IN", {
  weekday: "long",
  day: "numeric",
  month: "long",
  year: "numeric"
})
  const todayB = bookings.filter(b => b.date === TODAY && b.status !== 'cancelled')
  const todayRevenue = todayB.reduce(
  (s, b) => s + (b.amount || 0),
  0
)

const boxStats = boxes
  .filter(box => box.active)
  .map(box => {

    const boxBookings = todayB.filter(
      b => b.box_id === box.id
    )

    return {
      id: box.id,
      name: box.name,
      bookings: boxBookings.length,
      revenue: boxBookings.reduce(
        (s, b) => s + (b.amount || 0),
        0
      )
    }

  })
  const total = 12, booked = todayB.length, avail = Math.max(0, total-booked)
  const occ = Math.round(booked/total*100)
  const mon = bookings.filter(b => b.date.startsWith(TODAY.slice(0,7)) && b.status !== 'cancelled')
  const rev = mon.reduce((s,b) => s+(b.amount||0), 0)

  // Timeline
  const slots = []
  for (let hh=0; hh<24; hh++) for (let m=0; m<60; m+=30)
    slots.push(String(hh).padStart(2,'0')+':'+String(m).padStart(2,'0'))
  const seen = new Set()

  // Weekly chart
  const days = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']
  const weekDays = Array.from({length:7}, (_,i) => {
    const d = new Date(now); d.setDate(d.getDate()-(6-i))
    const ds = d.toISOString().split('T')[0]
    const cnt = bookings.filter(b => b.date===ds && b.status!=='cancelled').length
    return { label: days[d.getDay()]+(ds===TODAY?'★':''), cnt, isToday: ds===TODAY, isHigh: cnt>=8 }
  })

  const recentB = [...bookings].sort((a,b)=>b.id-a.id).slice(0,4)
  const upcomingB = bookings.filter(b=>b.date>=TODAY&&b.status!=='cancelled').sort((a,b)=>a.date.localeCompare(b.date)||a.from.localeCompare(b.from)).slice(0,5)

 const reduceSlot = async (id) => {
    // handled via window.confirm
    const b = bookings.find(x => x.id === id)
    if (!b) return
    const hrs = calcH(b.from, b.to)
    if (hrs <= 0.5) { alert('Minimum 30 mins — cannot reduce further'); return }
    const [th, tm] = b.to.split(':').map(Number)
    const newMin = tm===0?30:0, newH = tm===0?th-1:th
    const newTo = String(newH).padStart(2,'0')+':'+String(newMin).padStart(2,'0')
    if (!window.confirm(`Reduce ${b.name}'s booking to ${t12(b.from)}–${t12(newTo)}?`)) return
    // handled in parent via context
    return { id, newTo }
  }

  const today =
  new Date()
    .toISOString()
    .split('T')[0]

const currentMonth =
  new Date().getMonth()

const currentYear =
  new Date().getFullYear()

const todayExpense =
  expenses
    .filter(
      e =>
        e.expense_date === today
    )
    .reduce(
      (sum, e) =>
        sum + Number(e.amount || 0),
      0
    )

const monthRevenue =
  bookings
    .filter(b => {

      const d =
        new Date(b.date)

      return (
        d.getMonth() === currentMonth &&
        d.getFullYear() === currentYear &&
        b.status !== 'cancelled'
      )

    })
    .reduce(
      (sum, b) =>
        sum + Number(b.amount || 0),
      0
    )

const monthExpense =
  expenses
    .filter(e => {

      const d =
        new Date(
          e.expense_date
        )

      return (
        d.getMonth() === currentMonth &&
        d.getFullYear() === currentYear
      )

    })
    .reduce(
      (sum, e) =>
        sum + Number(e.amount || 0),
      0
    )

const todayProfit =
  todayRevenue - todayExpense

const monthProfit =
  monthRevenue - monthExpense

  return (
    <div className="page">
      <motion.div
  className="ph"
  initial={{ opacity: 0, y: -20 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.5 }}
>
  <div>
    <div
      className="ph-title"
      style={{
        fontSize: "30px",
        fontWeight: "700"
      }}
    >
      {greet}
    </div>

    <div
      className="ph-sub"
      style={{
        marginTop: "6px"
      }}
    >
      🏏 HITZONE Box Cricket
    </div>

    <div
      style={{
        marginTop: "8px",
        color: "#64748b",
        fontSize: "14px"
      }}
    >
      📅 {todayDate}
    </div>
  </div>
</motion.div>

     <div className="qa-grid">

  <div
    className="qa-card"
    onClick={() => go('calendar')}
  >
    <span className="qa-icon">📅</span>
    <div className="qa-label">Calendar View</div>
    <div className="qa-sub">Month overview</div>
  </div>

  <div
    className="qa-card primary"
    onClick={() => onNewBooking()}
  >
    <span className="qa-icon">➕</span>
    <div className="qa-label">New Booking</div>
    <div className="qa-sub">Add single booking</div>
  </div>

  <div
    className="qa-card"
    onClick={onRecurring}
  >
    <span className="qa-icon">🔁</span>
    <div className="qa-label">Recurring Booking</div>
    <div className="qa-sub">Weekly / daily repeat</div>
  </div>

</div>

      <div className="sg">
        <div className="stat"><div className="sh2"><div className="si si-b">📅</div></div><div className="sv">
  <CountUp end={booked} duration={1.3} />
</div><div className="sl">Today's Bookings</div></div>
        <div className="stat"><div className="sh2"><div className="si si-r">🔴</div></div><div className="sv">
  <CountUp end={booked} duration={1.3} />
</div><div className="sl">Slots Booked</div></div>
        <div className="stat"><div className="sh2"><div className="si si-g">🟢</div></div><div className="sv">
  <CountUp end={avail} duration={1.3} />
</div><div className="sl">Available Slots</div></div>
        <div className="stat">
          <div className="sh2"><div className="si si-p">%</div></div>
          <div className="sv">
  <CountUp end={occ} duration={1.3} />%
</div>
          <div className="sl">Occupancy</div>
          <div className="obar"><div className="ofill" style={{width:occ+'%'}}/></div>
        </div>
        <div className="stat"><div className="sh2"><div className="si si-y">₹</div></div><div className="sv">
  ₹
  <CountUp
    end={rev}
    separator=","
    duration={1.5}
  />
</div><div className="sl">Monthly Revenue</div></div>
        <div className="stat"><div className="sh2"><div className="si si-b">🏏</div></div><div className="sv">
  <CountUp end={mon.length} duration={1.3} />
</div><div className="sl">Monthly Bookings</div></div>
      </div>
      <div className="sg">

  <div className="stat">
    <div className="sh2">
      <div className="si si-g">💰</div>
    </div>

    <div className="sv">
      ₹
<CountUp
  end={todayRevenue}
  separator=","
  duration={1.5}
/>
    </div>

    <div className="sl">
      Today's Revenue
    </div>
  </div>

  <div className="stat">
    <div className="sh2">
      <div className="si si-r">💸</div>
    </div>

    <div className="sv">
      ₹
<CountUp
  end={todayExpense}
  separator=","
  duration={1.5}
/>
    </div>

    <div className="sl">
      Today's Expense
    </div>
  </div>

  <div className="stat">
    <div className="sh2">
      <div className="si si-b">📈</div>
    </div>

    <div className="sv">
      ₹
<CountUp
  end={todayProfit}
  separator=","
  duration={1.5}
/>
    </div>

    <div className="sl">
      Today's Profit
    </div>
  </div>

  <div className="stat">
    <div className="sh2">
      <div className="si si-y">📊</div>
    </div>

    <div className="sv">
      ₹
<CountUp
  end={monthProfit}
  separator=","
  duration={1.5}
/>
    </div>

    <div className="sl">
      Monthly Profit
    </div>
  </div>

</div>
      <div className="card" style={{marginBottom:'20px'}}>
  <div className="ch">
    <span className="ct">
      🏏 Today's Box Performance
    </span>
  </div>
  <div
    style={{
      display:'grid',
      gridTemplateColumns:'repeat(auto-fit,minmax(220px,1fr))',
      gap:'12px'
    }}
  >
    {boxStats.map(box => (
      <div
        key={box.id}
        style={{
          border:'1px solid #e5e7eb',
          borderRadius:'12px',
          padding:'14px'
        }}
      >
        <h4>{box.name}</h4>

        <div>
          Bookings:
          <strong> {box.bookings}</strong>
        </div>

        <div>
          Revenue:
          <strong>
            ₹{box.revenue.toLocaleString('en-IN')}
          </strong>
        </div>
      </div>
    ))}
  </div>

  <div
    style={{
      marginTop:'15px',
      fontWeight:'700'
    }}
  >
    Total Revenue:
    ₹{todayRevenue.toLocaleString('en-IN')}
  </div>
</div>

      <div className="dg2">
        <div className="card">
          <div className="ch">
            <span className="ct">📅 Today's Slot Status</span>
            <span style={{display:'flex',gap:'10px',fontSize:'12px'}}>
              <span style={{display:'flex',alignItems:'center',gap:'4px'}}>
                <span style={{width:'10px',height:'10px',background:'#fee2e2',border:'1.5px solid #fca5a5',borderRadius:'3px',display:'inline-block'}}/>
                <span style={{color:'var(--tx2)'}}>Booked</span>
              </span>
              <span style={{display:'flex',alignItems:'center',gap:'4px'}}>
                <span style={{width:'10px',height:'10px',background:'var(--bl)',border:'1.5px solid var(--blue)',borderRadius:'3px',display:'inline-block'}}/>
                <span style={{color:'var(--tx2)'}}>Available</span>
              </span>
            </span>
          </div>
          <div className="tl-wrap">
            <TimelineSlots slots={slots} bookings={bookings} onBook={(t) => onNewBooking(null, TODAY, t)}/>
          </div>
        </div>
        <div style={{display:'flex',flexDirection:'column',gap:'14px'}}>
          <div className="card">
            <div className="ch"><span className="ct">📊 Weekly Trend</span></div>
            <div className="bw">
              {weekDays.map((d,i) => (
                <div key={i} className="br">
                  <span className="bl2">{d.label}</span>
                  <div className="bt"><div className="bf" style={{width:Math.min(100,d.cnt*10+5)+'%',background:d.isToday?'var(--blue)':d.isHigh?'var(--red)':'var(--bm)'}}/></div>
                  <span className="bv">{d.cnt}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="card">
            <div className="ch"><span className="ct">Recent Bookings</span><span className="cl" onClick={() => go('bookings')}>All →</span></div>
            <div className="blist">
              {recentB.map(b => (
                <div key={b.id} className="bi" onClick={() => onNewBooking(b.id)}>
                  <div className="av" style={{background:clr(b.id)+'22',color:clr(b.id)}}>{ini(b.name)}</div>
                  <div className="bi-info"><div className="bi-name">{b.name}</div><div className="bi-sub">{fmtD(b.date)}</div></div>
                  <div className="bi-r"><div className="bi-time">{t12(b.from)}–{t12(b.to)}</div><span className={`badge ${bc(b.status)}`}>{b.status}</span></div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="dg2b">
        <div className="card">
          <div className="ch"><span className="ct">⏰ Upcoming Bookings</span><span className="cl" onClick={() => go('bookings')}>All →</span></div>
          <div className="blist">
            {upcomingB.length ? upcomingB.map(b => (
              <div key={b.id} className="bi" onClick={() => onNewBooking(b.id)}>
                <div className="av" style={{background:clr(b.id)+'22',color:clr(b.id)}}>{ini(b.name)}</div>
                <div className="bi-info"><div className="bi-name">{b.name}</div><div className="bi-sub">{fmtD(b.date)}</div></div>
                <div className="bi-r"><div className="bi-time">{t12(b.from)}–{t12(b.to)}</div><span className={`badge ${bc(b.status)}`}>{b.status}</span></div>
              </div>
            )) : <div style={{textAlign:'center',color:'var(--tx3)',padding:'16px',fontSize:'13px'}}>No upcoming bookings</div>}
          </div>
        </div>
        <div className="card">
          <div className="ch"><span className="ct">🔁 Recurring Groups</span><span className="cl" onClick={() => go('recurring')}>Manage →</span></div>
          <div className="rec-list">
            {recurGroups.length ? recurGroups.slice(0,3).map(r => (
              <div key={r.gid} className="rec-item">
                <div className="av" style={{background:'var(--bl)',color:'var(--blue)'}}>{ini(r.name)}</div>
                <div className="rec-info"><div className="rec-name">{r.name}</div><div className="rec-sub">{r.days.join(', ')} · {t12(r.from)}–{t12(r.to)}</div></div>
                <span className="rec-badge">{r.created} bookings</span>
              </div>
            )) : <div style={{textAlign:'center',color:'var(--tx3)',fontSize:'13px',padding:'10px'}}>No recurring bookings yet</div>}
          </div>
          <button className="btn btn-p btn-sm" style={{marginTop:'14px',width:'100%'}} onClick={onRecurring}>🔁 Add Recurring Booking</button>
        </div>
      </div>
    </div>
  )
}

function TimelineSlots({ slots, bookings, onBook }) {
  const seen = new Set()
  const { setBookings, showToast } = useApp()

  const reduceSlot = async (id) => {
    const b = bookings.find(x => x.id === id)
    if (!b) return
    const hrs = calcH(b.from, b.to)
    if (hrs <= 1) {
  showToast('Minimum 1 hour — cannot reduce further', 'e')
  return
}
    const [th, tm] = b.to.split(':').map(Number)

const totalMins = (th * 60 + tm) - 60

const newH = Math.floor(totalMins / 60)
const newMin = totalMins % 60

const newTo =
  String(newH).padStart(2, '0') +
  ':' +
  String(newMin).padStart(2, '0')
    if (!window.confirm(`Reduce ${b.name}'s booking to ${t12(b.from)}–${t12(newTo)}?`)) return
   const { error } = await supabase
  .from('bookings')
  .update({
    end_time: newTo,
    amount: calcH(b.from, newTo) * 1500
  })
  .eq('id', id)

if (error) {
  console.error(error)
  showToast('Update Failed', 'e')
  return
}
    const updated = bookings.map(bk => bk.id===id ? {...bk, to:newTo, amount:calcH(bk.from,newTo)*1500} : bk)
    setBookings(updated)
    localStorage.setItem('hz_b', JSON.stringify(updated))
    showToast(`Booking reduced to ${t12(b.from)}–${t12(newTo)} ✅`, 's')
  }

  return slots.map(t => {
    const b = bookings.find(b => b.date===TODAY && b.from<=t && b.to>t && b.status!=='cancelled')
    if (b) {
      const isFirst = !seen.has(b.id)
      seen.add(b.id)
      const hrs = calcH(b.from, b.to)
      const canReduce = hrs > 1
      const [th,tm] = b.to.split(':').map(Number)
      const prevMin = tm===0?30:0, prevH = tm===0?th-1:th
      const lastSlot = String(prevH).padStart(2,'0')+':'+String(prevMin).padStart(2,'0')
      const isLastSlot = t === lastSlot
      if (isFirst) {
        return (
          <div key={t} className="tl-row">
            <span className="tl-time">{t12(t)}</span>
            <div className="tl-slot tl-booked" style={{cursor:'pointer',gap:'8px'}} onClick={() => onBook && onBook(b.id, true)}>
              <span style={{flex:1}}>🔴 <strong>{b.name}</strong> &nbsp;<span style={{fontSize:'11px',opacity:.7}}>{t12(b.from)} – {t12(b.to)} · {hrs}h</span></span>
              {canReduce && <button onClick={e=>{e.stopPropagation();reduceSlot(b.id)}} title="Remove last 1 hour" style={{background:'#dc2626',color:'#fff',border:'none',borderRadius:'6px',padding:'3px 9px',fontSize:'11px',fontWeight:700,cursor:'pointer',flexShrink:0}}>−1hr</button>}
              <span className="tl-tag tag-b" style={{marginLeft:0}}>✏️ EDIT</span>
            </div>
          </div>
        )
      } else {
        return (
          <div key={t} className="tl-row">
            <span className="tl-time">{t12(t)}</span>
            <div className="tl-slot tl-booked" style={{cursor:'pointer',opacity:.75}} onClick={() => onBook && onBook(b.id, true)}>
              <span style={{fontSize:'12px',color:'#b91c1c'}}>↳ {b.name}</span>
              {isLastSlot && canReduce
                ? <button onClick={e=>{e.stopPropagation();reduceSlot(b.id)}} title="Remove last 1 hour" style={{background:'#dc2626',color:'#fff',border:'none',borderRadius:'6px',padding:'3px 9px',fontSize:'11px',fontWeight:700,cursor:'pointer',flexShrink:0,marginLeft:'auto'}}>−1hr</button>
                : <span className="tl-tag tag-b" style={{marginLeft:'auto'}}>BOOKED</span>
              }
            </div>
          </div>
        )
      }
    }
    return (
      <div key={t} className="tl-row">
        <span className="tl-time">{t12(t)}</span>
        <div className="tl-slot tl-avail" onClick={() => onBook && onBook(null, null, t)}>
          <span>🟢 Available</span><span className="tl-tag tag-a">TAP TO BOOK</span>
        </div>
      </div>
    )
  })
}
