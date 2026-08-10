import React from 'react'
import { useApp } from '../context/AppContext'

const PAGE_TITLES = {
  dashboard: 'Dashboard',
  calendar: 'Calendar',
  bookings: 'Bookings',
  recurring: 'Recurring Bookings',
  customers: 'Customers',
  reports: 'Reports',
  notifications: 'Notifications',
  settings: 'Settings'
}

export default function Navbar() {
  const { currentPage, go, dark, setDark, setSidebarOpen, notifs } = useApp()
  const now = new Date()
  const dateStr = now.toLocaleDateString('en-IN', {day:'numeric', month:'short', year:'numeric'})
  const hasUnread = notifs.some(n => !n.read)

  return (
    <header className="navbar">
      <button
        className="menu-btn"
        onClick={() => setSidebarOpen(true)}
      >☰</button>
      <div
  className="nav-title"
  style={{
    minWidth: 0,
    flex: 1,
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    whiteSpace: 'nowrap'
  }}
>
  {PAGE_TITLES[currentPage] || currentPage}
</div>
      <div
  className="nav-acts"
  style={{
    flexShrink: 0
  }}
>
        <div className="date-badge">{dateStr}</div>
        <button className="ic-btn" onClick={() => setDark(d => !d)}>{dark ? '☀️' : '🌙'}</button>
        <button className="ic-btn" onClick={() => go('notifications')} style={{position:'relative'}}>
          🔔{hasUnread && <span className="ndot"/>}
        </button>
        <div
          className="av"
          style={{background:'var(--blue)',color:'#fff',width:'32px',height:'32px',fontSize:'11px',borderRadius:'50%',cursor:'pointer',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700,flexShrink:0}}
          onClick={() => go('settings')}
        >HA</div>
      </div>
    </header>
  )
}