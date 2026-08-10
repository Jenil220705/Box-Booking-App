import React, { useState } from 'react'
import { useApp } from '../context/AppContext'
import { TODAY, t12, fmtD, bc, ini, clr } from '../utils/helpers'
import ReportCard from '../components/ReportCard'

export default function ReportsPage() {
  const { bookings, showToast } = useApp()
  const [period, setPeriod] = useState('month')

  let list = [...bookings]
  if (period === 'month') list = bookings.filter(b => b.date.startsWith(TODAY.slice(0,7)))
  if (period === 'week') {
    const wd = new Date(); wd.setDate(wd.getDate()-7)
    list = bookings.filter(b => b.date >= wd.toISOString().split('T')[0])
  }
  const active = list.filter(b => b.status !== 'cancelled')
  const rev = active.reduce((s,b) => s+(b.amount||0), 0)
  const occ = Math.min(100, Math.round(active.length/Math.max(1,active.length+4)*100))
  const hc = {}
  active.forEach(b => { const h = parseInt(b.from); hc[h] = (hc[h]||0)+1 })
  const ph = Object.entries(hc).sort((a,b) => b[1]-a[1])[0]

  const exportCSV = () => {
    const calcHLocal = (f, t) => {
      if (!f || !t) return 0
      const [fh,fm] = f.split(':').map(Number)
      const [th,tm] = t.split(':').map(Number)
      return Math.round(((th*60+tm)-(fh*60+fm))/60*10)/10
    }
    const rows = [['Name','Phone','Date','From','To','Hours','Amount','Status']]
    bookings.forEach(b => rows.push([b.name, b.phone, b.date, b.from, b.to, calcHLocal(b.from,b.to), (b.amount||0), b.status]))
    const a = document.createElement('a')
    a.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(rows.map(r=>r.join(',')).join('\n'))
    a.download = 'hitzone-'+TODAY+'.csv'
    a.click()
    showToast('CSV exported 📊', 's')
  }

  return (
    <div className="page">
      <div className="ph">
        <div><div className="ph-title">Reports & Analytics</div></div>
        <div style={{display:'flex',gap:'8px'}}>
          <button className="btn btn-s btn-sm" onClick={exportCSV}>📊 CSV</button>
          <button className="btn btn-s btn-sm" onClick={() => window.print()}>🖨️ Print</button>
        </div>
      </div>
      <div className="fbar">
        {[['month','This Month'],['week','This Week'],['all','All Time']].map(([p,l]) => (
          <button key={p} className={`chip${period===p?' active':''}`} onClick={() => setPeriod(p)}>{l}</button>
        ))}
      </div>
      <div className="rg">
        <div className="rc"><div className="rv" style={{color:'var(--blue)'}}>{active.length}</div><div className="rl2">Total Bookings</div></div>
        <div className="rc"><div className="rv" style={{color:'var(--ylw)'}}>₹{rev.toLocaleString('en-IN')}</div><div className="rl2">Revenue</div></div>
        <div className="rc"><div className="rv" style={{color:'var(--pur)'}}>{occ}%</div><div className="rl2">Occupancy</div></div>
        <div className="rc"><div className="rv" style={{color:'var(--red)'}}>{ph ? t12(String(ph[0]).padStart(2,'0')+':00') : '7 PM'}</div><div className="rl2">Peak Hour</div></div>
      </div>
      <div className="dg2b">
        <div className="card">
          <div className="ch"><span className="ct">⏱ Peak Hours</span></div>
          <div className="bw">
            {[['6–8 AM',40,'var(--blue)',24],['8–10 AM',52,'var(--blue)',31],['10–12 PM',35,'var(--bm)',21],['4–6 PM',60,'var(--bm)',36],['6–8 PM',90,'var(--ylw)',54],['8–10 PM',100,'var(--red)',60]].map(([l,w,c,v]) => (
              <div key={l} className="br">
                <span className="bl2">{l}</span>
                <div className="bt"><div className="bf" style={{width:w+'%',background:c}}/></div>
                <span className="bv">{v}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
      <div className="card" style={{marginTop:'14px'}}>
        <div className="ch"><span className="ct">Booking List</span></div>
        {/* Desktop */}
<div className="tw reports-table">
  <table>
    <thead>
      <tr>
        <th>Name</th>
        <th>Date</th>
        <th>Time</th>
        <th>Status</th>
        <th>Amount</th>
      </tr>
    </thead>

    <tbody>
      {active.slice(0,20).map(b => (
        <tr key={b.id}>
          <td>
            <div style={{fontWeight:700}}>
              {b.name}
            </div>

            <div
              style={{
                fontSize:'11px',
                color:'var(--tx3)'
              }}
            >
              {b.phone}
            </div>
          </td>

          <td>{fmtD(b.date)}</td>

          <td>
            {t12(b.from)} – {t12(b.to)}
          </td>

          <td>
            <span className={`badge ${bc(b.status)}`}>
              {b.status}
            </span>
          </td>

          <td
            style={{
              fontWeight:700,
              color:'var(--blue)'
            }}
          >
            ₹{(b.amount||0).toLocaleString('en-IN')}
          </td>
        </tr>
      ))}
    </tbody>
  </table>
</div>

{/* Mobile */}

<div className="reports-cards">

  {active.slice(0,20).map(b => (

    <ReportCard
      key={b.id}
      booking={b}
    />

  ))}

</div>
      </div>
    </div>
  )
}

