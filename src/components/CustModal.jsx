import React, { useState, useEffect } from 'react'
import { useApp } from '../context/AppContext'
import { supabase } from '../supabase'


export default function CustModal({ open, onClose, editId }) {
const {
  customers,
  setCustomers,
  showToast
} = useApp()
  const [cName, setCName] = useState('')
  const [cPhone, setCPhone] = useState('')
  const [cNotes, setCNotes] = useState('')

  useEffect(() => {
    if (!open) return
    if (editId) {
      const c = customers.find(x => x.id === editId)
      if (c) { setCName(c.name); setCPhone(c.phone); setCNotes(c.notes || '') }
    } else {
      setCName(''); setCPhone(''); setCNotes('')
    }
  }, [open, editId])

 const handleSave = async () => {

  if (!cName || !cPhone) {
    showToast('Name and phone required', 'e')
    return
  }

  if (editId) {

    const { error } = await supabase
      .from('customers')
      .update({
        name: cName,
        phone: cPhone,
        notes: cNotes
      })
      .eq('id', editId)

    if (error) {
      console.error(error)
      showToast('Update Failed', 'e')
      return
    }
    showToast('Updated ✅', 's')

onClose()

return

  } else {

    const { data, error } = await supabase
      .from('customers')
      .insert([
        {
          name: cName,
          phone: cPhone,
          notes: cNotes
        }
      ])
      .select()

    if (error) {
      console.error(error)
      showToast('Add Failed', 'e')
      return
    }

    const updated = [
      ...customers,
      {
        id: data[0].id,
        name: cName,
        phone: cPhone,
        notes: cNotes,
        cnt: 0,
        last: 'Never'
      }
    ]

    setCustomers(updated)

    showToast('Added ✅', 's')
  }

  onClose()
}

  if (!open) return null

  return (
    <div className="mb open" onClick={e => { if(e.target===e.currentTarget) onClose() }}>
      <div className="modal" style={{maxWidth:'400px'}}>
        <div className="mh">
          <span className="mt">{editId ? 'Edit Customer' : 'Add Customer'}</span>
          <button className="mc" onClick={onClose}>✕</button>
        </div>
        <div className="fg">
          <label className="flbl">Full Name *</label>
          <input className="fi" value={cName} onChange={e => setCName(e.target.value)} placeholder="Customer name"/>
        </div>
        <div className="fg">
          <label className="flbl">Mobile *</label>
          <input className="fi" type="tel" value={cPhone} onChange={e => setCPhone(e.target.value)} placeholder="+91 98765 43210"/>
        </div>
        <div className="fg">
          <label className="flbl">Notes</label>
          <textarea className="fta" value={cNotes} onChange={e => setCNotes(e.target.value)} placeholder="Any notes..."/>
        </div>
        <div className="fa">
          <button className="btn btn-s" onClick={onClose}>Cancel</button>
          <button className="btn btn-p" onClick={handleSave}>✅ Save</button>
        </div>
      </div>
    </div>
  )
}
