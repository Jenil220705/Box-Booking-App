import React, { useState } from 'react'
import { supabase } from '../supabase'

export default function AuthPage({ onLogin }) {
  const [email, setEmail] = useState('admin@hitzone.com')
  const [pass, setPass] = useState('admin123')
  const [err, setErr] = useState(false)

  const login = async () => {

  const { error } = await supabase.auth.signInWithPassword({
    email,
    password: pass
  })

  if (error) {
    console.error(error)
    setErr(true)
    return
  }

  setErr(false)
  onLogin()
}

  return (
    <div className="auth">
      <div className="auth-card">
        <div className="auth-logo">
          <div className="auth-icon">🏏</div>
          <div>
            <div className="auth-h1">HITZONE</div>
            <div className="auth-sub">Box Cricket · Admin Panel</div>
          </div>
        </div>
        {err && (
          <div className="auth-err">❌ Invalid email or password</div>
        )}
        <label className="auth-lbl">Email</label>
        <input
          className="auth-inp"
          type="email"
          value={email}
          onChange={e => setEmail(e.target.value)}
        />
        <label className="auth-lbl">Password</label>
        <input
          className="auth-inp"
          type="password"
          value={pass}
          onChange={e => setPass(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && login()}
        />
        <button className="auth-btn" onClick={login}>Sign In to Admin Panel →</button>
        <div className="auth-hint">HITZONE · Owner Access Only</div>
      </div>
    </div>
  )
}
