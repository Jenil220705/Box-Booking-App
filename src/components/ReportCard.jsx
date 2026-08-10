import React from 'react'
import { fmtD, t12, bc } from '../utils/helpers'

export default function ReportCard({ booking }) {
  return (
    <div className="cc">

      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "flex-start",
          marginBottom: "12px"
        }}
      >
        <div>
          <div className="cc-name">
            {booking.name}
          </div>

          <div
            style={{
              fontSize: "13px",
              color: "var(--tx2)",
              marginTop: "4px"
            }}
          >
            📱 {booking.phone}
          </div>
        </div>

        <span className={`badge ${bc(booking.status)}`}>
          {booking.status}
        </span>
      </div>

      <div className="cc-stats">

        <div className="cs">
          <div className="csv">
            {fmtD(booking.date)}
          </div>
          <div className="csl">
            Date
          </div>
        </div>

        <div className="cs">
          <div className="csv">
            {t12(booking.from)}
          </div>
          <div className="csl">
            From
          </div>
        </div>

        <div className="cs">
          <div className="csv">
            {t12(booking.to)}
          </div>
          <div className="csl">
            To
          </div>
        </div>

        <div className="cs">
          <div
            className="csv"
            style={{
              color: "var(--blue)"
            }}
          >
            ₹{(booking.amount || 0).toLocaleString("en-IN")}
          </div>

          <div className="csl">
            Amount
          </div>
        </div>

      </div>

    </div>
  )
}