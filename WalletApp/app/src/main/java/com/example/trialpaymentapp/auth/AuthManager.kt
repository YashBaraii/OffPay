package com.example.trialpaymentapp.auth

import com.example.trialpaymentapp.data.AppDatabase
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore


private val local: Any
    get() {
        TODO()
    }


class AuthManager(
    private val firebaseAuth: FirebaseAuth,
    private val appDatabase: AppDatabase,
    private val firestore: FirebaseFirestore
) {
    // Example helper functions
    fun getCurrentUserId(): String? = firebaseAuth.currentUser?.uid
    fun isLoggedIn(): Boolean = firebaseAuth.currentUser != null
}
