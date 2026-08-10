import React, { useState, useEffect } from 'react'
import { useApp } from '../context/AppContext'
import { TODAY, calcH, t12, fmtD, buildTimeOptions } from '../utils/helpers'
import { supabase } from '../supabase'

const TIME_OPTIONS = buildTimeOptions()
const DAY_NAMES = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']

export default function RecurModal({

  open,

  onClose,

  editData

}) {
  const {
  bookings,
  setBookings,
  customers,
  setCustomers,
  recurGroups,
  setRecurGroups,
  cfg,
  addNotif,
  showToast,
  boxes
} = useApp()

  const [rName, setRName] = useState('')
  const [rPhone, setRPhone] = useState('')
  const [rDate, setRDate] = useState(TODAY)
  const [rFrom, setRFrom] = useState('19:00')
  const [rTo, setRTo] = useState('21:00')
  const [rWeeks, setRWeeks] = useState(4)
  const [rRate, setRRate] = useState('')
 const [rBoxId, setRBoxId] = useState('')
  const [selDays, setSelDays] = useState([1]) // Mon default
  const activeBoxes = boxes.filter(box => box.active)
const showBoxField = activeBoxes.length > 1


useEffect(() => {
  console.log(
  "EDIT DATA RECEIVED =>",
  editData
)

  if (!editData) {

    setRName("")
    setRPhone("")
    setRDate(TODAY)
    setRFrom("19:00")
    setRTo("21:00")
    setRWeeks(4)
    setRRate('')
    setSelDays([1])

    if (boxes?.length) {
      setRBoxId(boxes[0].id)
    }

    return
  }

  setRName(editData.name || "")
  setRPhone(editData.phone || "")
  setRFrom(
  editData.from || "19:00"
)
  setRTo(
  editData.to || "21:00"
)
  setRWeeks(editData.weeks || 4)
  setRRate(
  editData.rate_per_hour || ""
)
  setRRate(editData.rate || '')

  setSelDays(
    (editData.days || []).map(
      day => DAY_NAMES.indexOf(day)
    )
  )

  const selectedBox =
    boxes.find(
      b => b.name === editData.box
    )

  if (selectedBox) {
    setRBoxId(selectedBox.id)
  }

}, [editData, boxes])

  const toggleDay = (d) => {
    setSelDays(prev => prev.includes(d) ? prev.filter(x=>x!==d) : [...prev, d])
  }

 const preview = () => {

  const names =
    selDays
      .map(d => DAY_NAMES[d])
      .join(' + ')

  const total =
    selDays.length * rWeeks

  return `${rName || 'Customer'} ·${
  boxes.find(
  b => String(b.id) === String(rBoxId)
)?.name || ''
} · ${names} · ${rWeeks} weeks → ${total} bookings will be created`

}


const saveRecur = async () => {

  console.log(
    "EDIT DATA =>",
    editData
  )

  if (
    editData &&
    !editData.gid
  ) {

    console.log(
      "BROKEN EDIT DATA",
      editData
    )

    showToast(
      "Recurring id missing",
      "e"
    )

    return
  }

  console.log(
    "EDIT DATA =>",
    editData
  )

 if (editData) {

  const gid = editData.gid

  // delete old bookings
  const { error: delErr } =
    await supabase
      .from("bookings")
      .delete()
      .eq(
        "recurring_group_id",
        gid
      )

  if (delErr) {
    alert(delErr.message)
    return
  }

  // update recurring group
  const { error: grpErr } =
    await supabase
      .from("recurring_groups")
      .update({
        customer_name: rName,
        phone: rPhone,
        box_id: rBoxId,
        days: selDays,
        start_time: rFrom,
        end_time: rTo,
        weeks: parseInt(rWeeks),
        rate_per_hour: parseFloat(rRate) || 0,
      })
      .eq("id", gid)

  if (grpErr) {
    alert(grpErr.message)
    return
  }

  const bookingsToInsert = []

for (let w = 0; w < weeks; w++) {

  for (const dayOfWeek of selDays) {

    const bookingDate = new Date(rDate + "T12:00:00")

    const diff =
      (dayOfWeek - bookingDate.getDay() + 7) % 7

    bookingDate.setDate(
      bookingDate.getDate() +
      diff +
      (w * 7)
    )

    const bookingDateStr =
      bookingDate.toISOString().split("T")[0]

    // CHECK CONFLICT BEFORE PUSH
    const { data: existing, error } = await supabase
  .from("bookings")
  .select("*")
  console.log("ALL BOOKINGS =", existing)
console.log("CHECK DATE =", bookingDateStr)
console.log("CHECK BOX =", rBoxId)

    if (error) {

  console.error(error)

  if (error.code === "23505") {

    showToast("❌ Slot already booked", "e")
    return

  }

  alert(error.message)
  return
}

    const conflict = existing.some(b =>
      b.status !== "cancelled" &&
      rFrom < b.end_time &&
      rTo > b.start_time
    )

    if (conflict) {

      showToast(
        `❌ ${bookingDateStr} ${rFrom}-${rTo} already booked`,
        "e"
      )

      return
    }

    bookingsToInsert.push({

      customer_name: rName,
      phone: rPhone,
      booking_date: bookingDateStr,
      start_time: rFrom,
      end_time: rTo,
      status: "confirmed",
     amount:
  calcH(rFrom, rTo) *
  (parseFloat(rRate) || 0),

rate_per_hour:
  parseFloat(rRate) || 0,
      box_id: rBoxId,
      recurring_group_id: gid

    })

    created++

  }

}

  const { error: insertErr } =
    await supabase
      .from("bookings")
      .insert(bookingsToInsert)

  if (insertErr) {
    alert(insertErr.message)
    return
  }

  const updated =
    recurGroups.map(r =>
      r.gid === gid
        ? {
            ...r,
            name: rName,
            phone: rPhone,
            box:
              boxes.find(
                b =>
                  String(b.id) ===
                  String(rBoxId)
              )?.name,
            days:
              selDays.map(
                d =>
                  DAY_NAMES[d]
              ),
            from: rFrom,
            to: rTo,
            weeks:
              parseInt(rWeeks),
            created:
              bookingsToInsert.length
          }
        : r
    )

  setRecurGroups(updated)

  localStorage.setItem(
    "hz_r",
    JSON.stringify(updated)
  )

  showToast(
    "Recurring updated",
    "s"
  )

  onClose()

  const ph = rPhone.replace(/\D/g, "")

const msg = (cfg.recurWaTmpl || "")
.replace(/{name}/g, rName)
.replace(/{date}/g, fmtD(rDate))
.replace(/{from}/g, t12(rFrom))
.replace(/{to}/g, t12(rTo))
.replace(/{weeks}/g, rWeeks)

setTimeout(() => {

window.open(

`https://wa.me/91${ph}?text=${encodeURIComponent(msg)}`,

"_blank"

)

},300)

  return
}

  
    if (!rName || !rDate || !rFrom || !rTo || !rBoxId || !rRate) {showToast('Fill required fields', 'e'); return }
    if (!selDays.length) { showToast('Select at least one day', 'e'); return }
    const weeks = parseInt(rWeeks) || 4
    const { data: groupData, error: groupError } = await supabase
  .from("recurring_groups")
  .insert({
    customer_name: rName,
    phone: rPhone,
    box_id: rBoxId,
    days: selDays,
    start_time: rFrom,
    end_time: rTo,
    weeks: weeks,
rate_per_hour: parseFloat(rRate) || 0,
  })
  .select()
  .single()

if (groupError) {
  console.log("==============");
  console.log("GROUP ERROR");
  console.log(groupError);
  console.log(JSON.stringify(groupError, null, 2));
  console.log("==============");
  alert(groupError.message);
  return;
}

const gid = groupData.id
    let created = 0
    const startDate = new Date(rDate+'T00:00:00')

    const bookingsToInsert = []

for (let w = 0; w < weeks; w++) {

  selDays.forEach(dayOfWeek => {

    const bookingDate =
      new Date(rDate + "T12:00:00")

    const diff =
      (dayOfWeek -
        bookingDate.getDay() +
        7) % 7

    bookingDate.setDate(
      bookingDate.getDate() +
      diff +
      (w * 7)
    )

    bookingsToInsert.push({

      customer_name: rName,

      phone: rPhone,

      booking_date:
        bookingDate
          .toISOString()
          .split("T")[0],

      start_time: rFrom,

      end_time: rTo,

      status: "confirmed",

     amount:
  calcH(rFrom, rTo) *
  (parseFloat(rRate) || 0),

rate_per_hour:
  parseFloat(rRate) || 0,

      box_id: rBoxId,

      recurring_group_id: gid

    })

    created++

  })

}

    const newGroup = {
  gid,
  name: rName,
  phone: rPhone,
  box:
  boxes.find(
  b => String(b.id) === String(rBoxId)
)?.name,
      days: selDays.map(d => DAY_NAMES[d]),
      from: rFrom, to: rTo,
      weeks, created,
      createdOn: new Date().toLocaleDateString('en-IN'),
      rate_per_hour: parseFloat(rRate) || 0
    }
    console.log(
  "INSERT DATA =>",
  JSON.stringify(bookingsToInsert, null, 2)
)

    const { data, error } = await supabase
  .from("bookings")
  .insert(bookingsToInsert)
  .select()

console.log("INSERT ERROR =>", error)
console.log("INSERT DATA =>", data)

if (error) {

  if (error.code === "23505") {
    showToast("❌ Slot already booked", "e")
  } else {
    showToast(error.message, "e")
  }

  return
}
const { data: check } = await supabase
  .from("bookings")
  .select("*")
  .eq("phone", rPhone)

console.log("DATABASE CHECK =>", check)

    const newGroups = [...recurGroups, newGroup]

setRecurGroups(newGroups)

localStorage.setItem(
  "hz_r",
  JSON.stringify(newGroups)
)
    addNotif('Recurring Created', `${rName} · ${selDays.map(d=>DAY_NAMES[d]).join('+')} · ${weeks} weeks · ${created} bookings`, 'info')
    const fill = (tmpl) =>
  tmpl
    .replace(/{name}/g, rName)
    .replace(/{from}/g, t12(rFrom))
    .replace(/{to}/g, t12(rTo))
    .replace(
      /{days}/g,
      selDays.map(d => DAY_NAMES[d]).join(", ")
    )
    .replace(/{weeks}/g, weeks)
    .replace(/{dates}/g, dates)

const dates = bookingsToInsert
  .map(b => "📅 " + fmtD(b.booking_date))
  .join("\n")

const waTemplate =
  cfg.recurringWaTmpl ||
`Hello {name},

🏏 *HITZONE Box Cricket*

Your recurring booking is confirmed ✅

🗓 Days: {days}
🕒 Time: {from} - {to}
📆 Weeks: {weeks}

${dates}

Thank you ❤️`

const msg =
  fill(waTemplate)
    .replace("{dates}", dates)

const phoneNo =
  rPhone.replace(/\D/g, "")

window.open(
  `https://wa.me/91${phoneNo}?text=${encodeURIComponent(msg)}`,
  "_blank"
)

const {
  data: existingCustomer
} = await supabase
  .from("customers")
  .select("*")
  .eq("phone", rPhone)
  .maybeSingle()

if (existingCustomer) {

  await supabase
    .from("customers")
    .update({
      cnt: (existingCustomer.cnt || 0) + created,
      active_count:
        (existingCustomer.active_count || 0) + created,
      last: "Today"
    })
    .eq("id", existingCustomer.id)

  setCustomers(prev =>
    prev.map(c =>
      c.id === existingCustomer.id
        ? {
            ...c,
            cnt: (c.cnt || 0) + created,
            active_count:
              (c.active_count || 0) + created,
            last: "Today"
          }
        : c
    )
  )

} else {

  const { data: newCustomer } =
    await supabase
      .from("customers")
      .insert([{
        name: rName,
        phone: rPhone,
        notes: "",
        cnt: created,
        active_count: created,
        last: "Today"
      }])
      .select()
      .single()

  if (newCustomer) {

    setCustomers(prev => [
      ...prev,
      newCustomer
    ])

  }

}

    showToast(`${created} bookings created 🔁`, 's')
    onClose()
  }

  if (!open) return null

  return (
    <div className="mb open" onClick={e => { if(e.target===e.currentTarget) onClose() }}>
      <div className="modal">
        <div className="mh">
          <span className="mt">🔁 Recurring Booking</span>
          <button className="mc" onClick={onClose}>✕</button>
        </div>
       
        <div className="fg">
  <label className="flbl">Mobile Number *</label>

  <input
    className="fi"
    type="tel"
    value={rPhone}
    onChange={e =>
      setRPhone(
        e.target.value
          .replace(/\D/g, "")
          .slice(0,10)
      )
    }
    maxLength={10}
    inputMode="numeric"
    placeholder="9876543210"
  />
</div>
         <div className="fg">
          <label className="flbl">Customer Name *</label>
          <input className="fi" value={rName} onChange={e => setRName(e.target.value)} placeholder="e.g. Rahul Shah"/>
        </div>
        <div className="fg">
  <label className="flbl">Amount / Hour (₹) *</label>
  <input
    className="fi"
    type="number"
    value={rRate}
    onChange={e => setRRate(e.target.value)}
    placeholder="Enter hourly rate"
    min="1"
  />
</div>
        <div className="fg">
          <label className="flbl">Start Date *</label>
          <input className="fi" type="date" value={rDate} onChange={e => setRDate(e.target.value)}/>
        </div>
        {showBoxField && (
  <div className="fg">

    <label className="flbl">Ground / Box *</label>

    <select
      className="fi"
      value={rBoxId}
      onChange={e => setRBoxId(e.target.value)}
    >
      {activeBoxes.map(box => (
        <option
          key={box.id}
          value={box.id}
        >
          {box.name}
        </option>
      ))}
    </select>

  </div>
)}
        <div className="fg">
          <label className="flbl">Time Slot *</label>
          <div className="tbar">
            <div className="tseg" style={{padding:'6px 10px'}}>
              <div className="tseg-lbl">From</div>
              <select value={rFrom} onChange={e => setRFrom(e.target.value)}>
                {TIME_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
            </div>
            <div className="tdiv"/>
            <div className="tseg" style={{padding:'6px 10px'}}>
              <div className="tseg-lbl">To</div>
              <select value={rTo} onChange={e => setRTo(e.target.value)}>
                {TIME_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
            </div>
          </div>
        </div>
        <div className="fg">
          <label className="flbl">Repeat on Days *</label>
          <div className="dp">
            {DAY_NAMES.map((d, i) => (
              <button key={i} type="button" className={`db${selDays.includes(i)?' sel':''}`}
                onClick={() => toggleDay(i)}>{d}</button>
            ))}
          </div>
        </div>
        <div className="fg">
          <label className="flbl">Number of Weeks *</label>
          <input className="fi" type="number" value={rWeeks} onChange={e => setRWeeks(e.target.value)} min="1" max="52"/>
        </div>
        
        <div style={{background:'var(--bl)',borderRadius:'var(--r)',padding:'12px 14px',fontSize:'13px',color:'var(--bd)',marginBottom:'4px',lineHeight:'1.6'}}>
          ℹ️ <strong>{preview()}</strong>
        </div>
        <div className="fa">
        
          <button className="btn btn-p" onClick={saveRecur}>{

editData

?

"💾 Save Changes"

:

"🔁 Create Bookings"

}</button>
        </div>
      </div>
    </div>
  )
}
