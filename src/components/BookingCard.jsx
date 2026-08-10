import React from 'react'
import { useApp } from '../context/AppContext'
import { t12, fmtD, bc, calcH } from '../utils/helpers'

export default function BookingCard({
  booking,
  index,
  onEdit,
  onWhatsApp,
  onDelete
}) {
    const { boxes } = useApp()

const activeBoxes = boxes.filter(box => box.active)

const showBox = activeBoxes.length > 1
  return (
    <div className="booking-card">

      <div className="booking-card-head">

        <div className="booking-user">

          <div className="booking-index">
            #{index + 1}
          </div>

          <div>

            <div className="booking-name">
              {booking.name}
            </div>

            <div className="booking-phone">
              📱 {booking.phone}
            </div>

          </div>

        </div>

        <span className={`badge ${bc(booking.status)}`}>
          {booking.status}
        </span>

      </div>

      <div className="booking-grid">

        <div>
          <small>Amount</small>
          <strong>
            ₹{(booking.amount || 0).toLocaleString("en-IN")}
          </strong>
        </div>

        <div>
          <small>Date</small>
          <strong>{fmtD(booking.date)}</strong>
        </div>

        <div>
          <small>Time</small>
          <strong>
            {t12(booking.from)} - {t12(booking.to)}
          </strong>
        </div>

        <div>
          <small>Duration</small>
          <strong>{calcH(booking.from, booking.to)}h</strong>
        </div>

        {showBox && (
  <div>
    <small>Box</small>
    <strong>
      {boxes.find(box => box.id === booking.box_id)?.name}
    </strong>
  </div>
)}

        

      </div>

      <div className="booking-actions">

        <button
          className="ab edit"
         onClick={onEdit}
        >
          ✏️
        </button>

        <button
          className="ab wa"
          onClick={onWhatsApp}
        >
          💬
        </button>

        <button
          className="ab del"
          onClick={onDelete}
        >
          🗑️
        </button>

      </div>

    </div>
  )
}
