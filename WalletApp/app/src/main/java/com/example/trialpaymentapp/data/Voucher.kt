package com.example.trialpaymentapp.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "vouchers")
data class Voucher(
    @PrimaryKey val id: String,                // Unique voucher ID (UUID or QR content hash)
    val senderId: String,                      // UID of the sender
    val recipientId: String?,                  // UID of recipient (null until redeemed)
    val amount: Double,                        // Payment amount
    val timestamp: Long = System.currentTimeMillis(),
    val status: String = "ISSUED",             // "ISSUED", "REDEEMED", "CANCELLED"
    val signature: String,                     // Cryptographic signature for authenticity
    var isSynced: Boolean = false              // Firestore sync flag
)
