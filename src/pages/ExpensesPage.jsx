import { useApp } from '../context/AppContext'
import { useState } from 'react'
import { supabase } from '../supabase'



export default function ExpensePage() {

  const { expenses, setExpenses } = useApp()

const [title, setTitle] = useState('')
const [amount, setAmount] = useState('')
const [category, setCategory] = useState('Ground')
const [note, setNote] = useState('')
const [editingId, setEditingId] = useState(null)
const [dateFilter, setDateFilter] =
  useState('all')
const [categoryFilter, setCategoryFilter] =
  useState('all')
  const [fromDate, setFromDate] = useState('')
const [toDate, setToDate] = useState('')

  const addExpense = async () => {

    console.log('editingId =', editingId)

  if (!title || !amount) return

  if (editingId !== null) {

  const { error } = await supabase
    .from('expenses')
    .update({
      title,
      amount,
      category,
      note
    })
    .eq('id', editingId)

  if (error) {
    console.log(error)
    return
  }

  const { data: updatedExpenses } = await supabase
    .from('expenses')
    .select('*')
    .order('id', { ascending: true })

  setExpenses(updatedExpenses || [])

  setEditingId(null)
  setTitle('')
  setAmount('')
  setCategory('Ground')
  setNote('')

  return
}

  

  const { data, error } =
    await supabase
      .from('expenses')
      .insert([
        {
  title,
  amount,
  category,
  note,
  expense_date:
    new Date()
      .toISOString()
      .split('T')[0]
}
      ])
      .select()

      console.log('editingId =', editingId)
console.log('data =', data)
console.log('error =', error)

  if (error) {
    console.log(error)
    return
  }

  setExpenses([
    data[0],
    ...expenses
  ])

  setTitle('')
  setAmount('')
  setCategory('Ground')
setNote('')
}

const deleteExpense = async (id) => {

  const ok = window.confirm(
    'Are you sure you want to delete this expense?'
  )

  if (!ok) return


  const { error } =
    await supabase
      .from('expenses')
      .delete()
      .eq('id', id)

  if (error) {

    console.error(error)

    return

  }

  setExpenses(
    prev =>
      prev.filter(
        e => e.id !== id
      )
  )

}
const today =
  new Date()
    .toISOString()
    .split('T')[0]

    const now = new Date()

const startOfWeek = new Date(now)
startOfWeek.setDate(now.getDate() - now.getDay())

const endOfWeek = new Date(startOfWeek)
endOfWeek.setDate(startOfWeek.getDate() + 6)

const weekStart =
  startOfWeek.toISOString().split('T')[0]

const weekEnd =
  endOfWeek.toISOString().split('T')[0]

const month =
  now.getMonth()

const year =
  now.getFullYear()


const safeExpenses = expenses.filter(Boolean)
    const filteredExpenses =
  expenses
    .filter(Boolean)
    .filter(exp => {

      let dateMatch = true
      let categoryMatch = true

      if (dateFilter === 'today') {

        dateMatch =
          exp.expense_date === today

      }

      if (
  dateFilter === 'custom' &&
  fromDate &&
  toDate
) {

  dateMatch =
    exp.expense_date >= fromDate &&
    exp.expense_date <= toDate

}

      else if (dateFilter === 'week') {

        dateMatch =
          exp.expense_date >= weekStart &&
          exp.expense_date <= weekEnd

      }

      else if (dateFilter === 'month') {

        const d = new Date(exp.expense_date)

        dateMatch =
          d.getMonth() === month &&
          d.getFullYear() === year

      }


      if (categoryFilter !== 'all') {

        categoryMatch =
          exp.category === categoryFilter

      }

      return (
        dateMatch &&
        categoryMatch
      )

    })
  

return (
    <div className="page">

      <div className="ph">
        <div className="ph-title">
          💸 Expense Tracker
        </div>
      </div>

      <div className="card">

        <h3>Total Expenses</h3>

        <h1>
          ₹{
            expenses
  .filter(Boolean)
  .reduce(
              (sum, e) =>
                sum + Number(e.amount || 0),
              0
            )
          }
        </h1>

      </div>
      <div
  className="card"
  style={{marginTop:'15px'}}
>

  <h3>
  {editingId
    ? 'Edit Expense'
    : 'Add Expense'}
</h3>

  <input
    className="fi"
    placeholder="Expense Name"
    value={title}
    onChange={e =>
      setTitle(e.target.value)
    }
  />

  <input
    className="fi"
    type="number"
    placeholder="Amount"
    value={amount}
    onChange={e =>
      setAmount(e.target.value)
    }
    style={{marginTop:'10px'}}
  />
  <select
  className="fi"
  value={category}
  onChange={e =>
    setCategory(e.target.value)
  }
  style={{marginTop:'10px'}}
>
  <option>Ground</option>
  <option>Electricity</option>
  <option>Water</option>
  <option>Salary</option>
  <option>Maintenance</option>
  <option>Marketing</option>
  <option>Other</option>
</select>

<textarea
  className="fi"
  placeholder="Note"
  value={note}
  onChange={e =>
    setNote(e.target.value)
  }
  style={{
    marginTop:'10px',
    minHeight:'80px'
  }}
/>

  <button
    className="btn btn-p"
    style={{marginTop:'10px'}}
    onClick={addExpense}
  >
   {editingId
 ? '💾 Update Expense'
 : '➕ Add Expense'}
  </button>

</div>
<div
  style={{
    display:'grid',
    gridTemplateColumns:'repeat(4,1fr)',
    gap:'10px',
    marginTop:'15px'
  }}
>

  <div className="card">
    <h4>Total Entries</h4>
    <h2>{expenses.length}</h2>
  </div>

  <div className="card">
    <h4>Ground</h4>
    <h2>
      ₹{
        expenses
  .filter(Boolean)
  .filter(e => e.category === 'Ground')
          .reduce((s,e)=>s+Number(e.amount||0),0)
      }
    </h2>
  </div>

  <div className="card">
    <h4>Salary</h4>
    <h2>
      ₹{
        expenses
  .filter(Boolean)
  .filter(e => e.category === 'Salary')
          .reduce((s,e)=>s+Number(e.amount||0),0)
      }
    </h2>
  </div>

  <div className="card">
    <h4>Electricity</h4>
    <h2>
      ₹{
        expenses
  .filter(Boolean)
  .filter(e => e.category === 'Electricity')
          .reduce((s,e)=>s+Number(e.amount||0),0)
      }
    </h2>
  </div>

  </div>

        
<div
  className="card"
  style={{marginTop:'15px'}}
>

  <h3>Filters</h3>

  <div
    style={{
      display:'flex',
      gap:'10px',
      marginBottom:'10px'
    }}
  >

    <button
className="btn btn-sm"
onClick={() => setDateFilter('all')}
>
All
</button>

<button
className="btn btn-sm"
onClick={() => setDateFilter('today')}
>
Today
</button>


<button
className="btn btn-sm"
onClick={() => setDateFilter('week')}
>
This Week
</button>

<button
className="btn btn-sm"
onClick={() => setDateFilter('month')}
>
This Month
</button>

<button
className="btn btn-sm"
onClick={() => setDateFilter('custom')}
>
Custom
</button>

  </div>

  {dateFilter === 'custom' && (

<div
  style={{
    display:'flex',
    gap:'10px',
    marginTop:'10px'
  }}
>

<input
  className="fi"
  type="date"
  value={fromDate}
  onChange={e =>
    setFromDate(e.target.value)
  }
/>

<input
  className="fi"
  type="date"
  value={toDate}
  onChange={e =>
    setToDate(e.target.value)
  }
/>

</div>

)}

  <select
    className="fi"
    value={categoryFilter}
    onChange={e =>
      setCategoryFilter(e.target.value)
    }
  >

    <option value="all">
      All Categories
    </option>

    <option value="Ground">
      Ground
    </option>

    <option value="Electricity">
      Electricity
    </option>

    <option value="Water">
      Water
    </option>

    <option value="Salary">
      Salary
    </option>

    <option value="Maintenance">
      Maintenance
    </option>

    <option value="Marketing">
      Marketing
    </option>

    <option value="Other">
      Other
    </option>

  </select>


</div>

     <div className="card" style={{marginTop:'15px'}}>

  <h3>Category Summary</h3>

  {[
    'Ground',
    'Electricity',
    'Water',
    'Salary',
    'Maintenance',
    'Marketing',
    'Other'
  ].map(cat => {

    const total =
  expenses
    .filter(Boolean)
    .filter(e => e.category === cat)
        .reduce(
          (sum,e) =>
            sum + Number(e.amount || 0),
          0
        )

    if(total === 0) return null

    return (

      <div
        key={cat}
        style={{
          display:'flex',
          justifyContent:'space-between',
          padding:'8px 0',
          borderBottom:'1px solid #eee'
        }}
      >

        <span>{cat}</span>

        <b>₹{total}</b>

      </div>

    )

  })}

</div>

<div className="card" style={{marginTop:'15px'}}>

  <h3>Top Category</h3>

  <h2>

    {

      Object.entries(

        expenses
  .filter(Boolean)
  .reduce((acc,e)=>{

    acc[e.category] =
      (acc[e.category] || 0)
      + Number(e.amount || 0)

    return acc

  },{})

      )

      .sort((a,b)=>b[1]-a[1])

      [0]?.[0]

      || 'No Data'

    }

  </h2>

</div>

<div className="card" style={{marginTop:'15px'}}>

  <h3>This Month Expense</h3>

  <h1>

    ₹{

      expenses

.filter(Boolean)

.filter(e => {

  const d = new Date(e.expense_date)

        const now = new Date()

        return (

          d.getMonth() === now.getMonth()

          &&

          d.getFullYear() === now.getFullYear()

        )

      })

      .reduce(

        (sum,e)=>

          sum + Number(e.amount || 0),

        0

      )

    }

  </h1>

</div>

       
        <h3>Expense List</h3>

       {[...filteredExpenses].reverse().map(exp => (

  <div
    key={exp.id}
    style={{
      padding:'10px',
      borderBottom:'1px solid #ddd',
      display:'flex',
      justifyContent:'space-between',
      alignItems:'center'
    }}
  >

    <div>

      <b>{exp.title}</b>

      <div>
        ₹{exp.amount}
      </div>
      <div>
  📂 {exp.category}
</div>

{exp.note && (
  <div>
    📝 {exp.note}
  </div>
)}

      <div>
        {exp.expense_date}
      </div>
      
    </div>

    <div
  style={{
    display:'flex',
    gap:'8px'
  }}
>

  <button
    className="btn btn-sm"
    onClick={() => {

      setEditingId(Number(exp.id))
      console.log("CLICKED ID:", exp.id)

      setTitle(exp.title || '')
      setAmount(exp.amount || '')
      setCategory(exp.category || 'Ground')
      setNote(exp.note || '')

      window.scrollTo({
        top:0,
        behavior:'smooth'
      })

    }}
  >
    ✏ Edit
  </button>

  <button
    className="btn btn-d btn-sm"
    onClick={() =>
      deleteExpense(exp.id)
    }
  >
    🗑 Delete
  </button>

</div>

  </div>

))}
{filteredExpenses.length === 0 && (

  <div
    style={{
      textAlign:'center',
      padding:'20px',
      color:'#666'
    }}
  >
    No expenses found
  </div>

)}
      </div>
  )
}