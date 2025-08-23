package com.example.trialpaymentapp

import android.app.Application
import androidx.work.*
import com.example.trialpaymentapp.data.AppDatabase
import com.example.trialpaymentapp.work.SyncWorker
import com.google.firebase.firestore.FirebaseFirestore
import java.util.concurrent.TimeUnit

class PaymentApp : Application() {
    val database: AppDatabase by lazy { AppDatabase.getDatabase(this) }
    lateinit var firestore: FirebaseFirestore
    companion object {
        lateinit var instance: PaymentApp
            private set
    }

    override fun onCreate() {
        super.onCreate()
        instance = this

        // Schedule periodic sync with WorkManager
        scheduleBackgroundSync()
        firestore = FirebaseFirestore.getInstance()
    }

    private fun scheduleBackgroundSync() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED) // only sync when online
            .build()

        val workRequest = PeriodicWorkRequestBuilder<SyncWorker>(
            15, TimeUnit.MINUTES // WorkManager requires minimum 15 min interval
        )
            .setConstraints(constraints)
            .build()

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "voucher_sync", // unique name for this work
            ExistingPeriodicWorkPolicy.KEEP, // keep previous work if exists
            workRequest
        )
    }
}
