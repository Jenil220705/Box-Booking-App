import React, { createContext, useContext, useState, useEffect, useCallback } from 'react'
import { supabase } from '../supabase'

const TODAY = new Date().toISOString().split('T')[0]
const TMR = new Date(Date.now()+86400000).toISOString().split('T')[0]
const YST = new Date(Date.now()-86400000).toISOString().split('T')[0]

const DEFAULT_BOOKINGS = [
  {id:1,name:'Rahul Shah',phone:'9876543210',date:TODAY,from:'07:00',to:'09:00',status:'confirmed',amount:3000},
  {id:2,name:'Amit Patel',phone:'8765432109',date:TODAY,from:'10:00',to:'12:00',status:'confirmed',amount:3000},
  {id:3,name:'Vijay Mehta',phone:'7654321098',date:TODAY,from:'14:00',to:'16:00',status:'pending',amount:3000},
  {id:4,name:'Kiran Dave',phone:'6543210987',date:TODAY,from:'19:00',to:'21:00',status:'confirmed',amount:3000},
  {id:5,name:'Suresh Joshi',phone:'5432109876',date:TMR,from:'08:00',to:'10:00',status:'pending',amount:3000},
  {id:6,name:'Raj Kumar',phone:'4321098765',date:TMR,from:'17:00',to:'19:00',status:'confirmed',amount:3000},
  {id:7,name:'Priya Shah',phone:'3210987654',date:YST,from:'09:00',to:'11:00',status:'completed',amount:3000},
  {id:8,name:'Dinesh Modi',phone:'2109876543',date:YST,from:'06:00',to:'08:00',status:'cancelled',amount:0},
]
const DEFAULT_CUSTOMERS = [
  {id:1,name:'Rahul Shah',phone:'9876543210',notes:'Regular customer',cnt:12,last:'Today'},
  {id:2,name:'Amit Patel',phone:'8765432109',notes:'Corporate',cnt:8,last:'Today'},
  {id:3,name:'Vijay Mehta',phone:'7654321098',notes:'Prefers evening',cnt:15,last:'Today'},
  {id:4,name:'Kiran Dave',phone:'6543210987',notes:'Weekly Sunday',cnt:20,last:'Today'},
  {id:5,name:'Suresh Joshi',phone:'5432109876',notes:'',cnt:5,last:'Tomorrow'},
  {id:6,name:'Raj Kumar',phone:'4321098765',notes:'Invoice needed',cnt:9,last:'Tomorrow'},
]
const DEFAULT_NOTIFS = [
  {id:1,title:'New Booking – Rahul Shah',msg:'Today 7:00–9:00 AM confirmed',type:'booking',read:false,time:'2 min ago'},
  {id:2,title:'Upcoming in 1 Hour',msg:'Amit Patel 10:00 AM starting soon',type:'reminder',read:false,time:'45 min ago'},
  {id:3,title:'⚠️ Conflict Detected',msg:'Overlap on Saturday 5–7 PM',type:'conflict',read:false,time:'1 hr ago'},
  {id:4,title:'Recurring Created',msg:'Kiran Dave – 4 Sundays 7–9 PM',type:'info',read:false,time:'3 hr ago'},
  {id:5,title:'New Customer',msg:'Suresh Joshi added',type:'success',read:true,time:'Yesterday'},
]

const DEFAULT_WA_TEMPLATE = `Hello {name},\n\n🏏 *HITZONE Box Cricket*\n\nBooking Confirmed ✅\n\n📅 Date: {date}\n⏰ Time: {from} – {to}\n\nPlease arrive 10 mins early.\n📍 HITZONE Ground, Rajkot\n\n_HITZONE Admin_`
const DEFAULT_RECUR_WA_TEMPLATE = `Hello {name},

🏏 *HITZONE Box Cricket*

Your recurring booking has been confirmed ✅

📅 Starting Date: {date}
⏰ Time: {from} - {to}
📆 Duration: {weeks} Weeks

Please arrive 10 mins early.

_HITZONE Admin_`
const DEFAULT_SMS_TEMPLATE = `Hi {name}, HITZONE Box Cricket booking confirmed! Date: {date}, Time: {from}-{to}. Arrive 10 mins early. Rajkot.`

const AppContext = createContext(null)

export function AppProvider({ children }) {
  const [bookings, setBookings] = useState(DEFAULT_BOOKINGS)
  const [customers, setCustomers] = useState(DEFAULT_CUSTOMERS)
  const [boxes, setBoxes] = useState([])
  const [expenses, setExpenses] = useState([])
  const [recurGroups, setRecurGroups] = useState([])
  const [notifs, setNotifs] = useState(DEFAULT_NOTIFS)
  const [cfg, setCfg] = useState({
  price:800,
  waTmpl:DEFAULT_WA_TEMPLATE,
  recurWaTmpl:DEFAULT_RECUR_WA_TEMPLATE,
  smsTmpl:DEFAULT_SMS_TEMPLATE
})
  const [dark, setDark] = useState(false)
  const [currentPage, setCurrentPage] = useState('dashboard')
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const [toast, setToast] = useState({ show: false, msg: '', type: 's' })
  const [calM, setCalM] = useState(new Date().getMonth())
  const [calY, setCalY] = useState(new Date().getFullYear())

  useEffect(() => {
  console.log("BOX STATE:", boxes)
}, [boxes])

useEffect(() => {
  loadBookings()
  loadCustomers()
  loadBoxes()
  loadExpenses()
  loadRecurring()
}, [])

async function loadBookings () {
  console.log('LOAD BOOKINGS CALLED')
  const { data, error } = await supabase
    .from('bookings')
    .select('*')

  console.log('DATA:', data)
  console.log('ERROR:', error)

  const now = new Date()

for (const booking of data) {

  const bookingEnd = new Date(
    `${booking.booking_date}T${booking.end_time}`
  )

  if (
    booking.status === 'confirmed' &&
    bookingEnd < now
  ) {

    await supabase
      .from('bookings')
      .update({
        status: 'completed'
      })
      .eq('id', booking.id)

  }

}

  const { data: freshData } =
  await supabase
    .from('bookings')
    .select('*')

if (freshData) {
 const formatted = freshData.map(b => ({
  id: b.id,
  name: b.customer_name,
  phone: b.phone,
  date: b.booking_date,
  booking_date: b.booking_date,
  from: b.start_time,
  start_time: b.start_time,
  to: b.end_time,
  end_time: b.end_time,
  status: b.status,
  amount: b.amount,
  box_id: String(b.box_id)
}))
    setBookings(formatted)
    window.dispatchEvent(new Event("booking-updated"))
    console.log("==============")
console.log("FORMATTED BOOKINGS")
console.log(formatted)
console.log("==============")
    

    localStorage.setItem(
  'hz_b',
  JSON.stringify(formatted)
)
  }
}



async function loadCustomers () {

  const { data, error } = await supabase
    .from('customers')
    .select('*')

  console.log('CUSTOMERS:', data)
  console.log('CUSTOMERS ERROR:', error)

  const { data: bookingsData } = await supabase
  .from('bookings')
  .select('phone')

  const bookingCountMap = {}

  bookingsData.forEach(b => {
  bookingCountMap[b.phone] =
    (bookingCountMap[b.phone] || 0) + 1
})
console.log(
  'COUNT MAP JSON:',
  JSON.stringify(bookingCountMap, null, 2)
)

  if (data) {

  const formatted = data.map(c => ({
  id: c.id,
  name: c.name,
  phone: c.phone,
  notes: c.notes || '',

  cnt: c.cnt || 0, // lifetime

  active_count:
  bookingCountMap[c.phone] || 0, // current active

  last: c.last || '-'
}))

    setCustomers(formatted)
  }
}

async function loadBoxes() {

  const result = await supabase
    .from('boxes')
    .select('*')

  console.log("FULL RESULT:", result)

  const { data, error } = result

  if (data) {
    setBoxes(data)
  }
}

async function loadExpenses() {

  const { data, error } =
    await supabase
      .from('expenses')
      .select('*')
      .order('id', { ascending: true })

  console.log("LOAD EXPENSES:", data)
  console.log("LOAD ERROR:", error)

  if (error) {
    console.error(error)
    return
  }

  setExpenses(data || [])
}

async function loadRecurring() {

  const { data, error } = await supabase
    .from("recurring_groups")
    .select(`
      *,
      boxes(name)
    `)

  if (error) {
    console.error(error)
    return
  }

  const formatted = data.map(r => ({
    gid: r.id,
    name: r.customer_name,
    phone: r.phone,
    box: r.boxes?.name || "-",
    days: r.days.map(d => ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][d]),
    from: r.start_time,
    to: r.end_time,
    weeks: r.weeks,
    created: r.days.length * r.weeks,
    createdOn: new Date(r.created_at).toLocaleDateString("en-IN")
  }))

  setRecurGroups(formatted)
}

useEffect(() => {

  console.log("Realtime Started")

  const channel = supabase
    .channel("bookings-realtime")

    .on(
      "postgres_changes",
      {
        event: "*",
        schema: "public",
        table: "bookings"
        
      },
      
      payload => {

        console.log("==============")
        console.log("REALTIME FIRED")
        console.log(payload)
        console.log("==============")

        loadBookings()

      }
    )
    .on(
  "postgres_changes",
  {
    event: "*",
    schema: "public",
    table: "recurring_groups"
  },
  () => {
    loadRecurring()
  }
)

    .subscribe(status => {

      console.log("SUBSCRIBE STATUS =>", status)

    })

  return () => {

    supabase.removeChannel(channel)

  }

}, [])


  // Load from localStorage
  useEffect(() => {
    try {
     //  const b = localStorage.getItem('hz_b'); if (b) setBookings(JSON.parse(b))
      // const c = localStorage.getItem('hz_c'); if (c) setCustomers(JSON.parse(c))
      const n = localStorage.getItem('hz_n'); if (n) setNotifs(JSON.parse(n))
      const s = localStorage.getItem('hz_s'); if (s) setCfg(prev => ({ ...prev, ...JSON.parse(s) }))
      const waTmpl = localStorage.getItem('hz_wa_tmpl'); if (waTmpl) setCfg(prev => ({ ...prev, waTmpl }))
      const smsTmpl = localStorage.getItem('hz_sms_tmpl'); if (smsTmpl) setCfg(prev => ({ ...prev, smsTmpl }))
    } catch (e) {}
  }, [])

  // Apply dark mode
  useEffect(() => {
    document.body.classList.toggle('dark', dark)
  }, [dark])

  const save = useCallback((b, c, r, n, s) => {
    try {
      localStorage.setItem('hz_b', JSON.stringify(b || bookings))
      localStorage.setItem('hz_c', JSON.stringify(c || customers))
      localStorage.setItem('hz_r', JSON.stringify(r || recurGroups))
      localStorage.setItem('hz_n', JSON.stringify(n || notifs))
      localStorage.setItem('hz_s', JSON.stringify(s || cfg))
    } catch (e) {}
  }, [bookings, customers, recurGroups, notifs, cfg])

  const showToast = useCallback((msg, type = 's') => {
    setToast({ show: true, msg, type })
    setTimeout(() => setToast(t => ({ ...t, show: false })), 3000)
  }, [])

  const addNotif = useCallback((title, msg, type = 'info') => {
    setNotifs(prev => {
      const updated = [{ id: Date.now(), title, msg, type, read: false, time: 'Just now' }, ...prev]
      localStorage.setItem('hz_n', JSON.stringify(updated))
      return updated
    })
  }, [])

  const go = useCallback((page) => {
    setCurrentPage(page)
    setSidebarOpen(false)
  }, [])

  return (
    <AppContext.Provider value={{
      bookings, setBookings,
      customers, setCustomers,loadCustomers,
      expenses, setExpenses,
      boxes, setBoxes,
      recurGroups, setRecurGroups,
      loadRecurring,
      notifs, setNotifs,
      cfg, setCfg,
      dark, setDark,
      currentPage, go,
      sidebarOpen, setSidebarOpen,
      toast, showToast,
      calM, setCalM,
      calY, setCalY,
      save, addNotif,
      DEFAULT_WA_TEMPLATE, DEFAULT_SMS_TEMPLATE
    }}>
      {children}
    </AppContext.Provider>
  )
}

export const useApp = () => useContext(AppContext)
export { TODAY, DEFAULT_WA_TEMPLATE, DEFAULT_SMS_TEMPLATE }
