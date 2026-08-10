import React, { useState, useEffect } from 'react'
import { useApp } from '../context/AppContext'
import { supabase } from '../supabase'

const DEFAULT_WA = `Hello {name},\n\n🏏 *HITZONE Box Cricket*\n\nBooking Confirmed ✅\n\n📅 Date: {date}\n⏰ Time: {from} – {to}\n\nPlease arrive 10 mins early.\n📍 HITZONE Ground, Rajkot\n\n_HITZONE Admin_`
const DEFAULT_SMS = `Hi {name}, HITZONE Box Cricket booking confirmed! Date: {date}, Time: {from}-{to}. Arrive 10 mins early. Rajkot.`

export default function SettingsPage() {
  const { cfg, setCfg, dark, setDark, showToast } = useApp()

  const [gn, setGn] = useState('HITZONE Box Cricket')
  const [addr, setAddr] = useState('Nr. Race Course, Rajkot, Gujarat')
  const [ph, setPh] = useState('+91 98765 43210')
  const [opens, setOpens] = useState('06:00')
  const [closes, setCloses] = useState('23:59')
  const [newPassword, setNewPassword] = useState('')
  const [waMsg, setWaMsg] = useState('') 
  const [smsMsg, setSmsMsg] = useState('')
  const [waAlerts, setWaAlerts] = useState(true)
  const [conflictDetect, setConflictDetect] = useState(true)
  const [boxCount, setBoxCount] = useState(0)
  const [recurWaMsg, setRecurWaMsg] = useState('')

  useEffect(() => {
 

  setWaMsg(
    localStorage.getItem("hz_wa_tmpl") || DEFAULT_WA
  )

  setSmsMsg(
    localStorage.getItem("hz_sms_tmpl") || DEFAULT_SMS
  )

  setRecurWaMsg(
    localStorage.getItem("hz_recur_wa_tmpl") || DEFAULT_WA
  )

  loadBoxCount()

}, [])

const loadBoxCount = async () => {

  const { count, error } =
    await supabase
      .from('boxes')
      .select('*', {
        count: 'exact',
        head: true
      })
      .eq('active', true)

  console.log('COUNT:', count)
  console.log('ERROR:', error)

  setBoxCount(count || 0)

}

const saveBoxCount = async () => {

  const { data: existingBoxes } =
    await supabase
      .from('boxes')
      .select('*')

  const activeBoxes =
  existingBoxes.filter(
    b => b.active
  )

const currentCount =
  activeBoxes.length

  if (boxCount === currentCount) {

    showToast(
      'No changes detected',
      'e'
    )

    return
  }
  if (boxCount > currentCount) {
    if (boxCount > currentCount) {

  const inactiveBoxes =
    existingBoxes.filter(
      b => !b.active
    )

  const need =
    boxCount - currentCount

  const ids =
    inactiveBoxes
      .slice(0, need)
      .map(b => b.id)

  const { error } =
    await supabase
      .from('boxes')
      .update({
        active: true
      })
      .in('id', ids)

  if (error) {
    console.error(error)
    return
  }

  showToast(
    `${need} box enabled`,
    's'
  )

  loadBoxCount()
}


  if (error) {

    console.error(error)

    showToast(
      'Box creation failed',
      'e'
    )

    return
  }

  showToast(
    `${newBoxes.length} box added`,
    's'
  )

  loadBoxCount()

}

if (boxCount < currentCount) {

  const boxesToDisable =
    existingBoxes
      .slice(boxCount)

  const ids =
    boxesToDisable.map(
      b => b.id
    )

  const { error } =
    await supabase
      .from('boxes')
      .update({
        active: false
      })
      .in('id', ids)

  if (error) {

    console.error(error)

    showToast(
      'Disable failed',
      'e'
    )

    return
  }

  showToast(
    `${ids.length} box disabled`,
    's'
  )

  loadBoxCount()

}

}

  
  

  const saveWA = () => {
    setCfg(prev => ({...prev, waTmpl: waMsg}))
    localStorage.setItem('hz_wa_tmpl', waMsg)
    showToast('WhatsApp template saved 💬', 's')
  }
  const saveRecurWA = () => {

  localStorage.setItem(
    "hz_recur_wa_tmpl",
    recurWaMsg
  )

  showToast(
    "Recurring WhatsApp template saved 💬",
    "s"
  )

}

  const saveSMS = () => {
    setCfg(prev => ({...prev, smsTmpl: smsMsg}))
    localStorage.setItem('hz_sms_tmpl', smsMsg)
    showToast('SMS template saved 📱', 's')
  }
const logout = async () => {
  await supabase.auth.signOut()
  window.location.reload()
}
const updatePassword = async () => {

  if (!newPassword) {
    showToast('Enter password', 'e')
    return
  }

  const { error } = await supabase.auth.updateUser({
    password: newPassword
  })

  if (error) {
    console.error(error)
    showToast('Password Update Failed', 'e')
    return
  }

  setNewPassword('')

  showToast('Password Updated ✅', 's')
}
  return (
    <div className="page">
      <div className="ph"><div className="ph-title">⚙️ Settings</div></div>
      <div className="set-g">
        {/* Ground */}
        <div className="set-s">
          <div className="set-t">🏟️ Ground</div>
          <div className="fg"><label className="flbl">Ground Name</label><input className="fi" value={gn} onChange={e=>setGn(e.target.value)}/></div>
          <div className="fg"><label className="flbl">Address</label><input className="fi" value={addr} onChange={e=>setAddr(e.target.value)}/></div>
          <div className="fg"><label className="flbl">Contact</label><input className="fi" value={ph} onChange={e=>setPh(e.target.value)}/></div>
          <div className="frow">
            <div className="fg"><label className="flbl">Opens</label><input className="fi" type="time" value={opens} onChange={e=>setOpens(e.target.value)}/></div>
            <div className="fg"><label className="flbl">Closes</label><input className="fi" type="time" value={closes} onChange={e=>setCloses(e.target.value)}/></div>
          </div>
         

<div className="fg">

  <label className="flbl">
    Number Of Boxes
  </label>

  <input
    className="fi"
    type="number"
    min="1"
    value={boxCount}
    onChange={e =>
      setBoxCount(
        Number(e.target.value)
      )
    }
  />

</div>
          <div
  className="fa"
  style={{
    justifyContent: 'flex-start',
    marginTop: '10px'
  }}
>
  <button
    className="btn btn-s btn-sm"
    onClick={saveBoxCount}
  >
    🏏 Update Boxes
  </button>
</div>
        </div>
        {/* Preferences */}
        <div className="set-s">
          <div className="set-t">⚙️ Preferences</div>
          <div className="trow">
            <div><div className="tlbl">Dark Mode</div></div>
            <label className="toggle">
              <input type="checkbox" checked={dark} onChange={e => setDark(e.target.checked)}/>
              <div className="ttrack"/><div className="tthumb"/>
            </label>
          </div>
          <div className="trow">
            <div><div className="tlbl">WhatsApp Alerts</div><div className="tdesc">Send confirmation via WhatsApp</div></div>
            <label className="toggle">
              <input type="checkbox" checked={waAlerts} onChange={e => setWaAlerts(e.target.checked)}/>
              <div className="ttrack"/><div className="tthumb"/>
            </label>
          </div>
          <div className="trow">
            <div><div className="tlbl">Conflict Detection</div><div className="tdesc">Block double booking</div></div>
            <label className="toggle">
              <input type="checkbox" checked={conflictDetect} onChange={e => setConflictDetect(e.target.checked)}/>
              <div className="ttrack"/><div className="tthumb"/>
            </label>
          </div>
        </div>
        {/* WA Template */}
        <div className="set-s" style={{gridColumn:'1/-1'}}>
          <div className="set-t">💬 WhatsApp Message Template</div>
          <div style={{fontSize:'12px',color:'var(--tx2)',marginBottom:'10px',lineHeight:1.6}}>
            Customize the booking confirmation message sent via WhatsApp.<br/>
            <strong>Variables:</strong>{' '}
            <code style={{background:'var(--bg)',padding:'1px 6px',borderRadius:'4px',fontSize:'11px'}}>{'{name}'}</code> Customer name &nbsp;·&nbsp;
            <code style={{background:'var(--bg)',padding:'1px 6px',borderRadius:'4px',fontSize:'11px'}}>{'{date}'}</code> Booking date &nbsp;·&nbsp;
            <code style={{background:'var(--bg)',padding:'1px 6px',borderRadius:'4px',fontSize:'11px'}}>{'{from}'}</code> Start time &nbsp;·&nbsp;
            <code style={{background:'var(--bg)',padding:'1px 6px',borderRadius:'4px',fontSize:'11px'}}>{'{to}'}</code> End time
          </div>
          <textarea className="fta" rows={7} style={{fontSize:'13px',lineHeight:1.7,fontFamily:'monospace'}}
            value={waMsg} onChange={e => setWaMsg(e.target.value)}/>
          <button className="btn btn-p btn-sm" style={{marginTop:'10px'}} onClick={saveWA}>💾 Save WhatsApp Template</button>
        </div>
        <div
  className="set-s"
  style={{gridColumn:'1/-1'}}
>

  <div className="set-t">
    🔁 Recurring WhatsApp Template
  </div>

  <div
    style={{
      fontSize:'12px',
      color:'var(--tx2)',
      marginBottom:'10px',
      lineHeight:1.6
    }}
  >

    Message sent after recurring booking creation.

    <br/>

    Variables :

    <code>{'{name}'}</code>

    <code>{'{date}'}</code>

    <code>{'{from}'}</code>

    <code>{'{to}'}</code>

  </div>

  <textarea
    className="fta"
    rows={7}
    style={{
      fontFamily:'monospace'
    }}
    value={recurWaMsg}
    onChange={e =>
      setRecurWaMsg(e.target.value)
    }
  />

  <button
    className="btn btn-p btn-sm"
    style={{marginTop:'10px'}}
    onClick={saveRecurWA}
  >
    💾 Save Recurring Template
  </button>

</div>
        {/* SMS Template */}
        <div className="set-s" style={{gridColumn:'1/-1'}}>
          <div className="set-t">📱 SMS Message Template</div>
          <div style={{fontSize:'12px',color:'var(--tx2)',marginBottom:'10px',lineHeight:1.6}}>
            Customize the SMS sent after booking. Keep it short (160 chars ideal).<br/>
            <strong>Variables:</strong>{' '}
            <code style={{background:'var(--bg)',padding:'1px 6px',borderRadius:'4px',fontSize:'11px'}}>{'{name}'}</code> &nbsp;·&nbsp;
            <code style={{background:'var(--bg)',padding:'1px 6px',borderRadius:'4px',fontSize:'11px'}}>{'{date}'}</code> &nbsp;·&nbsp;
            <code style={{background:'var(--bg)',padding:'1px 6px',borderRadius:'4px',fontSize:'11px'}}>{'{from}'}</code> &nbsp;·&nbsp;
            <code style={{background:'var(--bg)',padding:'1px 6px',borderRadius:'4px',fontSize:'11px'}}>{'{to}'}</code>
          </div>
          <textarea className="fta" rows={4} style={{fontSize:'13px',lineHeight:1.7,fontFamily:'monospace'}}
            value={smsMsg} onChange={e => setSmsMsg(e.target.value)}/>
          <button className="btn btn-p btn-sm" style={{marginTop:'10px'}} onClick={saveSMS}>💾 Save SMS Template</button>
        </div>
        {/* Admin Account */}
        <div className="set-s" style={{gridColumn:'1/-1'}}>
          <div className="set-t">🔐 Admin Account</div>
          <div className="frow">
            <div className="fg"><label className="flbl">Name</label><input className="fi" defaultValue="Hitzone Admin"/></div>
            <div className="fg"><label className="flbl">Email</label><input className="fi" defaultValue="admin@hitzone.com"/></div>
          </div>
          <div className="fg" style={{maxWidth:'300px'}}><label className="flbl">New Password</label><input
  className="fi"
  type="password"
  value={newPassword}
  onChange={e => setNewPassword(e.target.value)}
  placeholder="New Password"
/></div>
          <div className="fa" style={{justifyContent:'flex-start',marginTop:'10px'}}>
            <button
  className="btn btn-p btn-sm"
  onClick={updatePassword}
>
  🔐 Update Password
</button>
            <button
  className="btn btn-s btn-sm"
  onClick={logout}
>
  🚪 Logout
</button>
          </div>
        </div>
      </div>
    </div>
  )
}