import React from 'react'
import { supabase } from '../supabase'
import { useApp } from '../context/AppContext'
import { t12 } from '../utils/helpers'
import RecurringCard from "../components/RecurringCard";

export default function RecurringPage({

  onRecurring

}) {
  const {
  recurGroups,
  setRecurGroups,
  showToast,
  loadCustomers,
  boxes
} = useApp()

  const delRecur = async (group) => {

  if (
    !window.confirm(
      "Delete this recurring booking?"
    )
  ) return

  const { error } =
    await supabase
      .from("bookings")
      .delete()
      .eq(
        "recurring_group_id",
        group.gid
      )

await supabase
  .from("recurring_groups")
  .delete()
  .eq(
    "id",
    group.gid
  )

  if (error) {

    alert(error.message)

    return

  }

  const updated =
  recurGroups.filter(
    x => x.gid !== group.gid
  )

setRecurGroups(updated)

localStorage.setItem(
  "hz_r",
  JSON.stringify(updated)
)

// 👇 Customers realtime reload
await loadCustomers()

showToast(
  "Recurring deleted",
  "s"
)

}

const activeBoxes = boxes.filter(box => box.active)
const showBoxColumn = activeBoxes.length > 1

  return (
    
    <div className="page">
      <div className="ph">
        <div>
          <div className="ph-title">🔁 Recurring Bookings</div>
          <div className="ph-sub">Manage all recurring booking groups</div>
        </div>
        <button
  className="btn btn-p"
  onClick={() => onRecurring(null)}
>
  ➕ Create Recurring
</button>
      </div>

      <div style={{background:'var(--bl)',border:'1.5px solid var(--blue)',borderRadius:'var(--rl)',padding:'16px 20px',marginBottom:'20px',display:'flex',gap:'14px',alignItems:'flex-start'}}>
        <span style={{fontSize:'22px',flexShrink:0}}>ℹ️</span>
        <div>
          <div style={{fontWeight:700,fontSize:'14px',color:'var(--bd)',marginBottom:'4px'}}>How Recurring Bookings Work</div>
          <div style={{fontSize:'13px',color:'var(--bd)',lineHeight:1.6}}>
            Select customer name, time slot, which days (Mon/Tue/Wed etc), and how many weeks.
            System automatically creates all bookings. Example: Select <strong>Mon + Wed</strong> for <strong>4 weeks</strong> → 8 bookings created instantly.
          </div>
        </div>
      </div>

      <div className="desktop-booking-table">
<div className="tw">
        <table>
          <thead>
            <tr>
<th>Customer</th>
<th>Days</th>
<th>Time</th>
<th>Weeks</th>
<th>Bookings</th>

{showBoxColumn && <th>Box</th>}

<th>Created</th>
<th>Actions</th>
</tr>
          </thead>
          <tbody>
            {recurGroups.length ? recurGroups.map((r, i) => (
              <tr key={r.gid}>
                <td>
                  <div style={{fontWeight:700}}>{r.name}</div>
                  <div style={{fontSize:'12px',color:'var(--tx3)'}}>📱 {r.phone||'—'}</div>
                </td>
                
                <td><span style={{background:'var(--bl)',color:'var(--blue)',padding:'3px 10px',borderRadius:'99px',fontSize:'12px',fontWeight:700}}>{r.days.join(', ')}</span></td>
                <td style={{fontFamily:"'Space Grotesk',sans-serif",fontWeight:700}}>{t12(r.from)}–{t12(r.to)}</td>
                <td style={{fontWeight:600}}>{r.weeks} weeks</td>
                <td><span style={{background:'#dcfce7',color:'#16a34a',padding:'3px 10px',borderRadius:'99px',fontSize:'12px',fontWeight:700}}>{r.created} bookings</span></td>
                {showBoxColumn && (
  <td>{r.box || '-'}</td>
)}
                <td style={{fontSize:'13px',color:'var(--tx2)'}}>{r.createdOn||'—'}</td>
                <td>

  <div
    className="acts"
    style={{
      display: "flex",
      gap: "8px"
    }}
  >

    <button

      className="ab"

      title="Edit"

      onClick={() => {

  console.log(
    "CLICKED =>",
    r
  )

  onRecurring(r)

}}

    >

      ✏️

    </button>

    <button

      className="ab del"

      title="Delete"

      onClick={() => delRecur(r)}

    >

      🗑️

    </button>

  </div>

</td>
              </tr>
            )) : (
              <tr><td colSpan={showBoxColumn ? 8 : 7} style={{textAlign:'center',padding:'30px',color:'var(--tx3)'}}>No recurring bookings yet. Click "Create Recurring" to start.</td></tr>
            )}
          </tbody>
        </table>
      </div>
      </div>

<div className="booking-mobile-list">

  {recurGroups.length ? (

    recurGroups.map(r => (

      <RecurringCard
        key={r.gid}
        recurring={r}
        onEdit={onRecurring}
        onDelete={delRecur}
      />

    ))

  ) : (

    <div
      style={{
        textAlign:"center",
        padding:"40px",
        color:"var(--tx3)"
      }}
    >
      No recurring bookings yet.
    </div>

  )}

</div>
    </div>
  )
}
