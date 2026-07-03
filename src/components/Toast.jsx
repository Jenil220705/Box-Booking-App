import React from 'react'
import { useApp } from '../context/AppContext'

export default function Toast() {
  const { toast } = useApp()
  const ic = { s: '✅', e: '❌', i: 'ℹ️' }
  return (
    <div className={`toast${toast.show ? ' show' : ''}`}>
      <span>{ic[toast.type] || '✅'}</span>
      <span>{toast.msg}</span>
    </div>
  )
}
