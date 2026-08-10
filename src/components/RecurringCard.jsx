import React from "react";
import { useApp } from "../context/AppContext";
import { t12 } from "../utils/helpers";

export default function RecurringCard({
  recurring,
  onEdit,
  onDelete
}) {
    const { boxes } = useApp()

const activeBoxes =
boxes.filter(box => box.active)

const showBox =
activeBoxes.length > 1
  return (
    <div className="booking-card">

      <div className="booking-card-head">

        <div className="booking-user">

          <div className="booking-index">
            🔁
          </div>

          <div>

            <div className="booking-name">
              {recurring.name}
            </div>

            <div className="booking-phone">
              📱 {recurring.phone || "-"}
            </div>

          </div>

        </div>

      </div>

      <div className="booking-grid">

       

        <div>
          <small>Days</small>
          <strong>{recurring.days.join(", ")}</strong>
        </div>

        <div>
          <small>Time</small>
          <strong>
            {t12(recurring.from)} - {t12(recurring.to)}
          </strong>
        </div>

        <div>
          <small>Weeks</small>
          <strong>{recurring.weeks}</strong>
        </div>

        <div>
          <small>Bookings</small>
          <strong>{recurring.created}</strong>
        </div>

         {showBox && (
  <div>
    <small>Ground</small>
    <strong>{recurring.box || "-"}</strong>
  </div>
)}

        <div>
          <small>Created</small>
          <strong>{recurring.createdOn || "-"}</strong>
        </div>

      </div>

      <div className="booking-actions">

        <button
          className="ab edit"
          onClick={() => onEdit(recurring)}
        >
          ✏️
        </button>

        <button
          className="ab del"
          onClick={() => onDelete(recurring)}
        >
          🗑️
        </button>

      </div>

    </div>
  );
}