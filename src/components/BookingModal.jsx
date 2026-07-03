import React, { useState, useEffect } from 'react'
import { useApp } from '../context/AppContext'
import { supabase } from '../supabase'
import { TODAY, calcH, t12, fmtD, buildTimeOptions } from '../utils/helpers'

const TIME_OPTIONS = buildTimeOptions()

export default function BookingModal({ open, onClose, editId, prefillDate, prefillFrom }) {
  const { bookings, setBookings, customers, setCustomers, boxes, cfg, addNotif, showToast, save } = useApp()
  const [boxId, setBoxId] = useState('')

  const [name, setName] = useState('')
  const [phone, setPhone] = useState('')
  const [date, setDate] = useState(TODAY)
  const [from, setFrom] = useState('07:00')
  const [to, setTo] = useState('09:00')
  const [status, setStatus] = useState('confirmed')
  const [conflict, setConflict] = useState(null)

  useEffect(() => {
    if (!open) return
    setConflict(null)
    if (editId) {

      const b = bookings.find(x => x.id === editId)
      if (b) {
        setName(b.name); setPhone(b.phone); setDate(b.date)
        setFrom(b.from); setTo(b.to); setStatus(b.status)
        setBoxId(b.box_id || '')
      }
    } 
    else {
      const activeBoxes = boxes.filter(box => box.active)

if (activeBoxes.length > 0) {
  setBoxId(activeBoxes[0].id)
}

      setName(''); setPhone(''); setStatus('confirmed')
      setDate(prefillDate || TODAY)
      setFrom(prefillFrom || '07:00')
      // default +1hr
      if (prefillFrom) {
        const [h, m] = prefillFrom.split(':').map(Number)
        const toMins = h*60+m+60
        const toH = Math.floor(toMins/60)%24, toM = toMins%60
        setTo(String(toH).padStart(2,'0')+':'+String(toM).padStart(2,'0'))
      } else {
        setTo('09:00')
      }
    }
  }, [open, editId])

  const dur = calcH(from, to)

  const nameAutofill = (val) => {
    setName(val)
    const match = customers.find(c => c.name.toLowerCase() === val.toLowerCase())
    if (match) setPhone(match.phone)
  }

  const handleSave = async () => {
    const oldBooking = bookings.find(
  b => b.id === editId
)

      console.log("SAVE BUTTON CLICKED")

    if (
  !name ||
  !phone ||
  !date ||
  !from ||
  !to ||
  !boxId
) { showToast('Fill all required fields', 'e'); return }
    if (from >= to) { showToast('End time must be after start time', 'e'); return }
    const { data: existing, error: checkError } = await supabase
  .from("bookings")
  .select("*")
  .eq("booking_date", date)
  .eq("box_id", boxId)

if (checkError) {
  alert(checkError.message)
  return
}

const conflictB = existing.find(b =>
  b.id !== editId &&
  b.status !== "cancelled" &&
  from < b.end_time &&
  to > b.start_time
)

console.log("========== CHECK ==========")

console.log("DATE :", date)
console.log("BOX ID :", boxId)
console.log("FROM :", from)
console.log("TO :", to)

console.log("EXISTING BOOKINGS :", existing)

console.log("CONFLICT :", conflictB)

console.log("===========================")

if (conflictB) {

  showToast("❌ Slot already booked", "e")

  return
}

    console.log("BEFORE INSERT")
    console.log("AMT TEST START")

    const amt = calcH(from, to) * (cfg.price || 800)

    console.log("AMT =", amt)
    console.log("EDIT ID =", editId)

    console.log("TYPE =", typeof editId)
console.log("VALUE =", editId)
  
    let newBookings
   if (editId) {

  const { data: updateData, error } = await supabase
  .from('bookings')
  .update({
 customer_name: name,
 phone: phone,
 booking_date: date,
 start_time: from,
 end_time: to,
 amount: amt,
 status: status,
box_id: boxId
})
  .eq('id', editId)
  .select()

console.log("UPDATE RESULT:", updateData)
console.log("UPDATE ERROR:", error)

  if (error) {

  console.error(error)

  if (error.code === "23505") {

    showToast("❌ Slot already booked", "e")
    return

  }

  alert(error.message)
  return
}

  newBookings = bookings.map(b =>
    b.id === editId
      ? {
    ...b,
    name,
    phone,
    date,
    from,
    to,
    status,
    amount: amt,
    box_id: boxId
  }
      : b
  )

  setBookings(newBookings)
  if (oldBooking.phone !== phone) {

  setCustomers(prev =>
    prev.map(c => {

      if (c.phone === oldBooking.phone) {
        return {
          ...c,
          active_count: Math.max(
            0,
            (c.active_count || 0) - 1
          )
        }
      }

      if (c.phone === phone) {
        return {
          ...c,
          active_count:
            (c.active_count || 0) + 1
        }
      }

      return c
    })
  )

}
  showToast('Booking updated ✅', 's')
}else {

     console.log("Saving to Supabase...")

     console.log("GOING TO SUPABASE")

     const { data, error } = await supabase
       .from('bookings')
       .insert([
{
 customer_name: name,
 phone: phone,
 booking_date: date,
 start_time: from,
 end_time: to,
 amount: amt,
 status: status,
box_id: boxId
}
])
       .select()
if (error) {

  console.error(error)

  if (error.code === "23505") {

    showToast("❌ Slot already booked", "e")
    return

  }

  alert(error.message)
  return
}

     const nb = {
 id: data[0].id,
 name,
 phone,
 date,
 from,
 to,
 status,
amount: amt,
box_id: boxId
}

     newBookings = [...bookings, nb]
     setBookings(newBookings)
      addNotif('New Booking – '+name, `${fmtD(date)} ${t12(from)}–${t12(to)}`, 'booking')
      // update customers
   const {
  data: existingCustomer,
  error: customerError
} = await supabase
  .from('customers')
  .select('*')
  .eq('phone', phone)
  .maybeSingle()

console.log(
  "EXISTING CUSTOMER:",
  existingCustomer
)

console.log(
  "CUSTOMER ERROR:",
  customerError
)

if (existingCustomer) {

  await supabase
    .from('customers')
   .update({
  cnt: (existingCustomer.cnt || 0) + 1,
  active_count: (existingCustomer.active_count || 0) + 1,
  last: 'Today'
})
    .eq('id', existingCustomer.id)

  setCustomers(prev =>
    prev.map(c =>
      c.id === existingCustomer.id
        ? {
  ...c,
  cnt: (c.cnt || 0) + 1,
  active_count: (c.active_count || 0) + 1,
  last: 'Today'
}
        : c
    )
  )

} else {

  const {
  data: newCustomer,
  error: newCustomerError
} = await supabase
  .from('customers')
  .insert([
    {
      name,
      phone,
      notes: '',
      cnt: 1,
      active_count: 1,
      last: 'Today'
    }
  ])
  .select()
  .single()

console.log("NEW CUSTOMER:", newCustomer)
console.log("NEW CUSTOMER ERROR:", newCustomerError)

  if (newCustomer) {

    setCustomers(prev => [
      ...prev,
      {
        id: newCustomer.id,
        name: newCustomer.name,
        phone: newCustomer.phone,
        notes: newCustomer.notes || '',
        cnt: newCustomer.cnt || 0,
        active_count: newCustomer.active_count || 0,
        last: newCustomer.last || 'Today'
      }
    ])

  }

}
      showToast('Booking added ✅', 's')
    }
    localStorage.setItem('hz_b', JSON.stringify(newBookings))
    onClose()
    // Auto-send WA + SMS if not cancelled
    if (status !== 'cancelled') {
      const ph = phone.replace(/\D/g, '')
      const fillTmpl = tmpl => tmpl.replace(/{name}/g,name).replace(/{date}/g,fmtD(date)||date).replace(/{from}/g,t12(from)).replace(/{to}/g,t12(to))
      const waTmpl = fillTmpl(cfg.waTmpl || `Hello ${name},\n\n🏏 *HITZONE Box Cricket*\n\nBooking Confirmed ✅\n\n📅 Date: ${fmtD(date)}\n⏰ Time: ${t12(from)} – ${t12(to)}\n\nPlease arrive 10 mins early.\n📍 HITZONE Ground, Rajkot\n\n_HITZONE Admin_`)
      setTimeout(() => { window.open(`https://wa.me/91${ph}?text=${encodeURIComponent(waTmpl)}`, '_blank') }, 300)
      const smsTmpl = fillTmpl(cfg.smsTmpl || `Hi ${name}, HITZONE Box Cricket booking confirmed! Date: ${fmtD(date)}, Time: ${t12(from)}-${t12(to)}. Arrive 10 mins early. Rajkot.`)
      setTimeout(() => { window.open(`sms:${ph}?body=${encodeURIComponent(smsTmpl)}`, '_blank') }, 900)
    }
  }

  const sendWA = () => {
    if (!phone) { showToast('Enter mobile number first', 'e'); return }
    const ph = phone.replace(/\D/g, '')
    const fillTmpl = tmpl => tmpl.replace(/{name}/g,name||'Customer').replace(/{date}/g,fmtD(date)||date).replace(/{from}/g,t12(from)).replace(/{to}/g,t12(to))
    const waTmpl = fillTmpl(cfg.waTmpl || `Hello {name},\n\n🏏 *HITZONE Box Cricket*\n\nBooking Confirmed ✅\n\n📅 Date: {date}\n⏰ Time: {from} – {to}\n\nPlease arrive 10 mins early.\n📍 HITZONE Ground, Rajkot\n\n_HITZONE Admin_`)
    window.open(`https://wa.me/91${ph}?text=${encodeURIComponent(waTmpl)}`, '_blank')
  }

  if (!open) return null

  return (
    <div className="mb open" onClick={e => { if(e.target===e.currentTarget) onClose() }}>
      <div className="modal">
        <div className="mh">
          <span className="mt">{editId ? 'Edit Booking' : 'New Booking'}</span>
          <button className="mc" onClick={onClose}>✕</button>
        </div>
        {conflict && (
          <div className="conf" style={{display:'flex'}}>
            <span style={{fontSize:'20px',flexShrink:0}}>⚠️</span>
            <div>
              <div style={{fontWeight:700,color:'var(--red)',fontSize:'14px'}}>Slot Already Booked!</div>
              <div style={{fontSize:'12px',color:'#dc2626',marginTop:'3px'}}>{conflict}</div>
            </div>
          </div>
        )}
        <div className="fg">
          <label className="flbl">Customer Name *</label>
          <input className="fi" value={name} onChange={e => nameAutofill(e.target.value)}
            placeholder="e.g. Rahul Shah"
            list="namesDL"
          />
          <datalist id="namesDL">
            {customers.filter(c => c.name.toLowerCase().includes(name.toLowerCase())).map(c =>
              <option key={c.id} value={c.name}/>
            )}
          </datalist>
        </div>
        <div className="fg">
          <label className="flbl">Mobile Number *</label>
          <input className="fi" type="tel" value={phone} onChange={e => setPhone(e.target.value)} placeholder="+91 98765 43210"/>
        </div>
        <div className="fg">
  <label className="flbl">Box *</label>

  <select
  className="fs"
  value={boxId}
  onChange={e => setBoxId(e.target.value)}
>
  {boxes
    .filter(box => box.active)
    .map(box => (
      <option
        key={box.id}
        value={box.id}
      >
        {box.name}
      </option>
    ))}
</select>
</div>
        <div className="fg">
          <label className="flbl">Date *</label>
          <input className="fi" type="date" value={date} onChange={e => setDate(e.target.value)}/>
        </div>
        <div className="fg">
          <label className="flbl">Time Slot *</label>
          <div className="tbar">
            <div className="tseg" style={{padding:'6px 10px'}}>
              <div className="tseg-lbl">From</div>
              <select value={from} onChange={e => setFrom(e.target.value)}>
                {TIME_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
            </div>
            <div className="tdiv"/>
            <div className="tseg" style={{padding:'6px 10px'}}>
              <div className="tseg-lbl">To</div>
              <select value={to} onChange={e => setTo(e.target.value)}>
                {TIME_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
            </div>
            <div className="tdur">{dur > 0 ? dur+'h' : '–'}</div>
          </div>
        </div>
        <div className="fg">
          <label className="flbl">Status</label>
          <div className="fg">
</div>
          <select className="fs" value={status} onChange={e => setStatus(e.target.value)}>
           <option value="confirmed">✅ Confirmed</option>
           <option value="completed">🏆 Completed</option>
           <option value="cancelled">❌ Cancelled</option>
          </select>
        </div>
        <div className="fa">
          <button className="btn btn-s" onClick={onClose}>Cancel</button>
          <button className="btn btn-wa btn-sm" onClick={sendWA}>💬 WhatsApp</button>
          <button className="btn btn-p" onClick={handleSave}>✅ Save</button>
        </div>
      </div>
    </div>
  )
}
