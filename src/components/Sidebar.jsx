import React from 'react'
import { useApp } from '../context/AppContext'

export default function Sidebar({ onLogout }) {
  const { currentPage, go, sidebarOpen, setSidebarOpen, bookings, notifs } = useApp()

  const pendingCount = bookings.filter(b => b.status === 'pending').length
  const unreadCount = notifs.filter(n => !n.read).length

  const nav = (page) => { go(page); setSidebarOpen(false) }

  return (
    <>
      <div className={`sb-ov${sidebarOpen ? ' on' : ''}`} onClick={() => setSidebarOpen(false)} />
      <nav className={`sidebar${sidebarOpen ? ' open' : ''}`} id="sidebar">
        <div className="sb-top">
          <div className="sb-icon">🏏</div>
          <div>
            <div className="sb-name">HITZONE</div>
            <div className="sb-sub">Box Cricket</div>
          </div>
        </div>
        <div className="sb-nav">
          <div className="sb-sec">
            <div className="sb-sec-lbl">Main</div>
            <div className={`sbi${currentPage==='dashboard'?' active':''}`} onClick={() => nav('dashboard')}>
              <span className="sbi-ic">📊</span>Dashboard
            </div>
            <div className={`sbi${currentPage==='calendar'?' active':''}`} onClick={() => nav('calendar')}>
              <span className="sbi-ic">📅</span>Calendar
            </div>
            <div className={`sbi${currentPage==='bookings'?' active':''}`} onClick={() => nav('bookings')}>
              <span className="sbi-ic">📋</span>Bookings
              {pendingCount > 0 && <span className="sb-badge">{pendingCount}</span>}
            </div>
            <div className={`sbi${currentPage==='recurring'?' active':''}`} onClick={() => nav('recurring')}>
              <span className="sbi-ic">🔁</span>Recurring
            </div>
          </div>
          <div className="sb-sec">
            <div className="sb-sec-lbl">Management</div>
            <div className={`sbi${currentPage==='customers'?' active':''}`} onClick={() => nav('customers')}>
              <span className="sbi-ic">👥</span>Customers
            </div>
            <div className={`sbi${currentPage==='reports'?' active':''}`} onClick={() => nav('reports')}>
              <span className="sbi-ic">📈</span>Reports
            </div>
            <div
  className={`sbi${currentPage==='expenses' ? ' active' : ''}`}
  onClick={() => nav('expenses')}
>
  <span className="sbi-ic">💸</span>
  Expenses
</div>
          </div>
          <div className="sb-sec">
            <div className="sb-sec-lbl">System</div>
            <div className={`sbi${currentPage==='notifications'?' active':''}`} onClick={() => nav('notifications')}>
              <span className="sbi-ic">🔔</span>Notifications
              {unreadCount > 0 && <span className="sb-badge">{unreadCount}</span>}
            </div>
            <div className={`sbi${currentPage==='settings'?' active':''}`} onClick={() => nav('settings')}>
              <span className="sbi-ic">⚙️</span>Settings
            </div>
          </div>
        </div>
        <div className="sb-bot">
          <div className="sb-admin">
            <div className="av" style={{background:'var(--blue)',color:'#fff'}}>HA</div>
            <div style={{flex:1}}>
              <div className="sb-aname">Hitzone Admin</div>
              <div className="sb-arole">Owner · Full Access</div>
            </div>
            <button className="logout-btn" onClick={onLogout}>🚪</button>
          </div>
        </div>
      </nav>
    </>
  )
}
