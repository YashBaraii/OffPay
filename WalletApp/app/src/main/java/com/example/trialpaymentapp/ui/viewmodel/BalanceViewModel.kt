package com.example.trialpaymentapp.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.trialpaymentapp.data.Transaction
import com.example.trialpaymentapp.data.TransactionDao
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn

class BalanceViewModel(private val transactionDao: TransactionDao) : ViewModel() {

    val currentBalance: StateFlow<Double> = transactionDao.getAllTransactions()
        .map { transactions ->
            var balance = 0.0
            for (transaction in transactions) {
                when (transaction.type.uppercase()) {
                    // Assuming "CREDIT" or "RECEIVED" for incoming
                    "RECEIVED", "CREDIT" -> balance += transaction.amount
                    // Assuming "DEBIT" or "SENT" for outgoing
                    "SENT", "DEBIT" -> balance -= transaction.amount
                }
            }
            balance
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000L), // Keep active for 5s after last subscriber
            initialValue = 0.0 // Initial balance before DB query completes
        )
}
