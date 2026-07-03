import React, { useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { AppProvider, useApp } from './context/AppContext'
import AuthPage from './components/AuthPage'
import Sidebar from './components/Sidebar'
import Navbar from './components/Navbar'
import Toast from './components/Toast'
import BookingModal from './components/BookingModal'
import RecurModal from './components/RecurModal'
import CustModal from './components/CustModal'

import Dashboard from './pages/Dashboard'
import CalendarPage from './pages/CalendarPage'
import BookingsPage from './pages/BookingsPage'
import RecurringPage from './pages/RecurringPage'
import CustomersPage from './pages/CustomersPage'
import ReportsPage from './pages/ReportsPage'
import NotificationsPage from './pages/NotificationsPage'
import SettingsPage from './pages/SettingsPage'
import { useEffect } from 'react'
import { supabase } from './supabase'
import ExpensesPage from './pages/ExpensesPage'

function AppShell() {
  const { currentPage, go, save } = useApp()
  const [loggedIn, setLoggedIn] = useState(false)

  useEffect(() => {

  supabase.auth.getSession().then(({ data: { session } }) => {
    if (session) {
      setLoggedIn(true)
    }
  })

}, [])

  // Booking modal state
  const [bookingOpen, setBookingOpen] = useState(false)
  const [bookingEditId, setBookingEditId] = useState(null)
  const [bookingPrefillDate, setBookingPrefillDate] = useState(null)
  const [bookingPrefillFrom, setBookingPrefillFrom] = useState(null)

  // Recur modal state
  const [recurOpen, setRecurOpen] = useState(false)
  

const [recurEditData, setRecurEditData] = useState(null)

  // Customer modal state
  const [custOpen, setCustOpen] = useState(false)
  const [custEditId, setCustEditId] = useState(null)

  const handleLogin = () => { setLoggedIn(true) }
 const handleLogout = async () => {

  await supabase.auth.signOut()

  save()

  setLoggedIn(false)

}

  // Open booking modal: id=edit, date+from=prefill for quick book
  const openBookingModal = (id = null, date = null, from = null) => {
    setBookingEditId(id)
    setBookingPrefillDate(date)
    setBookingPrefillFrom(from)
    setBookingOpen(true)
  }

  const openRecurModal = (group = null) => {

  console.log(
    "OPEN RECUR =>",
    group
  )

  if (
    group &&
    group.gid
  ) {

    setRecurEditData(group)

  } else {

    setRecurEditData(null)

  }

  setRecurOpen(true)

}
  const openCustModal = () => { setCustEditId(null); setCustOpen(true) }
  const openEditCust = (id) => { setCustEditId(id); setCustOpen(true) }

  if (!loggedIn) return <AuthPage onLogin={handleLogin} />

  return (
    <>
      <div className="app">
  <Sidebar onLogout={handleLogout} />

  <div className="main">
    <Navbar />

    <AnimatePresence mode="wait">

      {currentPage === 'dashboard' && (
        <motion.div
          key="dashboard"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -20 }}
          transition={{ duration: 0.35 }}
        >
          <Dashboard
            onNewBooking={(id, date, from) => openBookingModal(id, date, from)}
            onRecurring={openRecurModal}
          />
        </motion.div>
      )}

      {currentPage === 'calendar' && (
  <motion.div
    key="calendar"
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    exit={{ opacity: 0, y: -20 }}
    transition={{ duration: 0.35 }}
  >
    <CalendarPage
      onNewBooking={(id, date) => openBookingModal(id, date)}
      onRecurring={openRecurModal}
    />
  </motion.div>
)}

      {currentPage === 'bookings' && (
  <motion.div
    key="bookings"
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    exit={{ opacity: 0, y: -20 }}
    transition={{ duration: 0.35 }}
  >
    <BookingsPage
      onNewBooking={(id) => openBookingModal(id)}
      onRecurring={openRecurModal}
    />
  </motion.div>
)}

      {currentPage === 'recurring' && (
  <motion.div
    key="recurring"
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    exit={{ opacity: 0, y: -20 }}
    transition={{ duration: 0.35 }}
  >
    <RecurringPage
      onRecurring={openRecurModal}
    />
  </motion.div>
)}
      {currentPage === 'customers' && (
  <motion.div
    key="customers"
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    exit={{ opacity: 0, y: -20 }}
    transition={{ duration: 0.35 }}
  >
    <CustomersPage
      onAddCust={openCustModal}
      onEditCust={openEditCust}
    />
  </motion.div>
)}

      {currentPage === 'reports' && (
  <motion.div
    key="reports"
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    exit={{ opacity: 0, y: -20 }}
    transition={{ duration: 0.35 }}
  >
    <ReportsPage />
  </motion.div>
)}
      {currentPage === 'notifications' && (
  <motion.div
    key="notifications"
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    exit={{ opacity: 0, y: -20 }}
    transition={{ duration: 0.35 }}
  >
    <NotificationsPage />
  </motion.div>
)}
      {currentPage === 'settings' && (
  <motion.div
    key="settings"
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    exit={{ opacity: 0, y: -20 }}
    transition={{ duration: 0.35 }}
  >
    <SettingsPage />
  </motion.div>
)}
      {currentPage === 'expenses' && (
  <motion.div
    key="expenses"
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    exit={{ opacity: 0, y: -20 }}
    transition={{ duration: 0.35 }}
  >
    <ExpensesPage />
  </motion.div>
)}

    </AnimatePresence>

  </div>
</div>

      <BookingModal
        open={bookingOpen}
        onClose={() => setBookingOpen(false)}
        editId={bookingEditId}
        prefillDate={bookingPrefillDate}
        prefillFrom={bookingPrefillFrom}
      />
      <RecurModal
  open={recurOpen}
  onClose={() => {

    setRecurOpen(false)

    setRecurEditData(null)

  }}

  editData={recurEditData}
/>
      <CustModal
        open={custOpen}
        onClose={() => setCustOpen(false)}
        editId={custEditId}
      />
      <Toast />
    </>
  )
}

export default function App() {
  return (
    <AppProvider>
      <AppShell />
    </AppProvider>
  )
}
