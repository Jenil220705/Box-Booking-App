import React from 'react'
import { useApp } from '../context/AppContext'

const NOTIF_IC = { booking:'📅', reminder:'⏰', conflict:'⚠️', info:'ℹ️', success:'✅' }
const NOTIF_BG = { booking:'rgba(14,165,233,.15)', reminder:'#fef9c3', conflict:'#fee2e2', info:'#dbeafe', success:'#dcfce7' }

export default function NotificationsPage() {
  const { notifs, setNotifs, showToast } = useApp()

  const readN = (id) => {
    const updated = notifs.map(n => n.id === id ? {...n, read:true} : n)
    setNotifs(updated)
    localStorage.setItem('hz_n', JSON.stringify(updated))
  }

  const markAllRead = () => {
    const updated = notifs.map(n => ({...n, read:true}))
    setNotifs(updated)
    localStorage.setItem('hz_n', JSON.stringify(updated))
    showToast('All read ✅', 's')
  }

  return (
    <div className="page">
      <div className="ph">
        <div><div className="ph-title">🔔 Notifications</div></div>
        <button className="btn btn-s btn-sm" onClick={markAllRead}>✅ Mark All Read</button>
      </div>
      <div className="nl">
        {notifs.map(n => (
          <div key={n.id} className={`ni${!n.read?' unread':''}`} onClick={() => readN(n.id)} style={{cursor:'pointer'}}>
            <div className="ni-ic" style={{background:NOTIF_BG[n.type]||'#f1f5f9'}}>{NOTIF_IC[n.type]||'📌'}</div>
            <div className="ni-body">
              <div className="ni-title">{n.title}</div>
              <div className="ni-desc">{n.msg}</div>
              <div className="ni-time">{n.time}</div>
            </div>
            {!n.read && <div style={{width:'8px',height:'8px',background:'var(--blue)',borderRadius:'50%',flexShrink:0,marginTop:'4px'}}/>}
          </div>
        ))}
      </div>
    </div>
  )
}
