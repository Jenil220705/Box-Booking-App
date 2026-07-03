import React, { useState, useEffect } from 'react'
import { useApp } from '../context/AppContext'
import { t12, fmtD, bc, ini, clr, MONTHS, DAYS } from '../utils/helpers'

export default function CalendarPage({ onNewBooking, onRecurring }) {
  const { bookings, boxes, calM, calY, setCalM, setCalY } = useApp()
  useEffect(() => {

  console.log("==============")
  console.log("BOOKINGS STATE")
  console.log(bookings)

  console.log("BOXES STATE")
  console.log(boxes)

  bookings.forEach(b => {

    console.log(
      "BOOKING ->",
      b.date,
      b.box_id,
      typeof b.box_id
    )

  })

  boxes.forEach(box => {

    console.log(
      "BOX ->",
      box.id,
      typeof box.id
    )

  })

  console.log("==============")

}, [bookings, boxes])
  const [dayDetail, setDayDetail] = useState(null) // {date, list}

  const changeMonth = (d) => {
    let m = calM + d, y = calY
    if (m > 11) { m = 0; y++ }
    if (m < 0) { m = 11; y-- }
    setCalM(m); setCalY(y)
  }
  const goToday = () => { setCalM(new Date().getMonth()); setCalY(new Date().getFullYear()) }

  const today = new Date()
  const first = new Date(calY, calM, 1).getDay()
  const dInM = new Date(calY, calM+1, 0).getDate()
  const prevD = new Date(calY, calM, 0).getDate()

  const calClick = (date) => {
  const dayB = bookings.filter(
  b =>
    (b.date || b.booking_date) === date &&
    b.status !== "cancelled" &&
    boxes.some(
      box =>
        String(box.id) === String(b.box_id) &&
        box.active
    )
)
  if (dayB.length) {
    setDayDetail({
      date,
      list: dayB
    })
  } else {
    onNewBooking(null, date)
  }
}

  const cells = []
  for (let i = first-1; i >= 0; i--)
    cells.push({ day: prevD-i, otherMonth: true })
  for (let d = 1; d <= dInM; d++) {
    const ds = `${calY}-${String(calM+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`
    const isT = d===today.getDate() && calM===today.getMonth() && calY===today.getFullYear()
   const dayB = bookings.filter(
  b =>
    (b.date || b.booking_date) === ds &&
    b.status !== "cancelled" &&
    boxes.some(
      box =>
        String(box.id) === String(b.box_id) &&
        box.active
    )
)
    cells.push({ day: d, ds, isToday: isT, bookings: dayB })
  }
  console.log("DAY DETAIL =>", dayDetail)
const groupedBookings =
  dayDetail
    ? boxes
        .filter(box => box.active)
        .map(box => ({
          ...box,
          bookings: dayDetail.list.filter(
            b => String(b.box_id) === String(box.id)
          )
        }))
    : []
    console.log("BOOKINGS =>", bookings)
    bookings.forEach(b => {
  console.log({
    date: b.date,
    booking_date: b.booking_date,
    from: b.from,
    start_time: b.start_time,
    to: b.to,
    end_time: b.end_time,
    name: b.name,
    customer_name: b.customer_name
  });
});
console.log("BOXES =>", boxes)
  return (
    <div className="page">
      <div className="ph">
        <div><div className="ph-title">📅 Calendar</div></div>
        <div style={{display:'flex',gap:'8px',flexWrap:'wrap'}}>
          <button className="btn btn-s btn-sm" onClick={onRecurring}>🔁 Recurring</button>
          <button className="btn btn-p" onClick={() => onNewBooking()}>➕ New Booking</button>
        </div>
      </div>
      <div className="card">
        <div className="cal-tb">
          <button className="cal-nav" onClick={() => changeMonth(-1)}>‹</button>
          <span className="cal-mn">{MONTHS[calM]} {calY}</span>
          <button className="cal-nav" onClick={() => changeMonth(1)}>›</button>
          <button className="cal-nav" onClick={goToday} style={{padding:'0 12px',width:'auto',fontSize:'13px',fontWeight:700}}>Today</button>
        </div>
        <div className="cal-g">
          {DAYS.map(d => <div key={d} className="cal-dh">{d}</div>)}
          {cells.map((c, i) => (
            <div key={i}
              className={`cal-day${c.otherMonth?' other-m':''}${c.isToday?' today':''}`}
              onClick={() => !c.otherMonth && calClick(c.ds)}
            >
              <div className="cal-dn">{c.day}</div>
              {(c.bookings||[]).slice(0,2).map((b,j) => (
                <div key={j} className="cal-ev">
  {
    boxes.find(
  x => String(x.id) === String(b.box_id)
)?.name
    || 'Box'
  }
  {' '}
  {t12(b.from)}
</div>
              ))}
              {(c.bookings||[]).length > 2 && <div style={{fontSize:'9px',color:'var(--tx3)'}}>+{c.bookings.length-2} more</div>}
            </div>
          ))}
        </div>
      </div>
      {dayDetail && (
        <div className="card" style={{marginTop:'14px'}}>
          <div className="ch">
            <span className="ct">📅 Bookings on {fmtD(dayDetail.date)}</span>
            <span className="cl" onClick={() => setDayDetail(null)}>Close ✕</span>
          </div>
          <div>
           
    {groupedBookings.map(box => (
  <div key={box.id}>

    <h3
      style={{
        marginTop:'15px',
        marginBottom:'10px'
      }}
    >
      🏏 {box.name}
    </h3>

    {box.bookings.length === 0 ? (

      <div
        style={{
          color:'#999',
          padding:'10px'
        }}
      >
        No bookings
      </div>

    ) : (

      box.bookings.map(b => (

        <div
          key={b.id}
          className="bi"
        >
          <div
            className="av"
            style={{
              background:
                clr(b.id)+'22',
              color:clr(b.id)
            }}
          >
            {ini(b.name)}
          </div>

          <div className="bi-info">
            <div className="bi-name">
              {b.name}
            </div>
          </div>

          <div className="bi-r">
            <div className="bi-time">
              {t12(b.from)}
              -
              {t12(b.to)}
            </div>

            <span
              className={`badge ${bc(b.status)}`}
            >
              {b.status}
            </span>
          </div>
        </div>

      ))

    )}

  </div>
))}
            
          </div>
        </div>
      )}
    </div>
  )
}
