package com.example.trialpaymentapp.work

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.trialpaymentapp.data.AppDatabase
import com.example.trialpaymentapp.data.Voucher
import com.example.trialpaymentapp.data.Transaction
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import kotlinx.coroutines.tasks.await

class SyncWorker(ctx: Context, params: WorkerParameters) : CoroutineWorker(ctx, params) {
    private val fs = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()
    private val db = AppDatabase.getDatabase(ctx)

    override suspend fun doWork(): Result {
        val user = auth.currentUser ?: return Result.success() // nothing to do if logged out
        val uid = user.uid

        return try {
            // ------- PUSH: Unsynced vouchers (Room -> Firestore) -------
            val unsyncedVouchers = db.voucherDao().getUnsyncedVouchers()
            unsyncedVouchers.forEach { v ->
                fs.collection("vouchers").document(v.id)
                    .set(v, SetOptions.merge()).await()
                db.voucherDao().markVoucherSynced(v.id, true)
            }

            // ------- PULL: Remote vouchers (Firestore -> Room) -------
            val remoteVouchersSnap = fs.collection("vouchers")
                .whereEqualTo("ownerUid", uid) // if you store ownerUid in Voucher
                .get().await()
            val remoteVouchers = remoteVouchersSnap.toObjects(Voucher::class.java)
            db.voucherDao().insertAll(remoteVouchers)

            // ------- PUSH: Unsynced transactions -------
            val unsyncedTxns = db.transactionDao().getUnsyncedTransactions()
            unsyncedTxns.forEach { t ->
                fs.collection("txns").document(t.id.toString())
                    .set(
                        mapOf(
                            "id" to t.id.toString(),
                            "sender" to uid, // adapt to your model
                            "receiver" to t.counterpartyId,
                            "amountCents" to (t.amount * 100).toLong(),
                            "timestamp" to com.google.firebase.Timestamp(t.timestamp / 1000, 0),
                            "status" to if (t.isSynced) "SETTLED" else "PENDING"
                        ),
                        SetOptions.merge()
                    ).await()
                db.transactionDao().updateTransactionSynced(t.id, true)
            }

            // ------- PULL: Remote transactions where I'm party -------
            val remoteTxnsSnap = fs.collection("txns")
                .whereEqualTo("sender", uid).get().await()
            val remoteTxnsSnap2 = fs.collection("txns")
                .whereEqualTo("receiver", uid).get().await()
            // TODO: map remote txn shape -> your Room Transaction and upsert (if you need)

            Result.success()
        } catch (e: Exception) {
            e.printStackTrace()
            Result.retry()
        }
    }
}
