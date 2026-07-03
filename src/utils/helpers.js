export const TODAY = new Date().toISOString().split('T')[0]
export const TMR = new Date(Date.now()+86400000).toISOString().split('T')[0]
export const YST = new Date(Date.now()-86400000).toISOString().split('T')[0]

export const CLRS = ['#0EA5E9','#6366f1','#8b5cf6','#f59e0b','#0891B2','#06b6d4','#14b8a6','#3b82f6']

export const ini = n => (n||'?').split(' ').map(x=>x[0]).join('').slice(0,2).toUpperCase()
export const clr = i => CLRS[Math.abs(i) % CLRS.length]

export const fmtD = s => {
  if (!s) return ''
  return new Date(s+'T00:00:00').toLocaleDateString('en-IN', {day:'numeric', month:'short', year:'numeric'})
}

export const t12 = t => {
  if (!t) return ''
  const [h, m] = t.split(':').map(Number)
  return `${h%12||12}:${String(m).padStart(2,'0')} ${h>=12?'PM':'AM'}`
}

export const bc = s => s==='confirmed'?'bc':s==='pending'?'bp':s==='completed'?'bco':'bx'

export const calcH = (f, t) => {
  if (!f || !t) return 0
  const [fh,fm] = f.split(':').map(Number)
  const [th,tm] = t.split(':').map(Number)
  return Math.round(((th*60+tm)-(fh*60+fm))/60*10)/10
}

export const buildTimeOptions = () => {
  const opts = []
  for (let h=0; h<24; h++) {
    for (let m=0; m<60; m+=30) {
      const val = String(h).padStart(2,'0')+':'+String(m).padStart(2,'0')
      opts.push({ value: val, label: t12(val) })
    }
  }
  return opts
}

export const MONTHS = ['January','February','March','April','May','June','July','August','September','October','November','December']
export const DAYS = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']
