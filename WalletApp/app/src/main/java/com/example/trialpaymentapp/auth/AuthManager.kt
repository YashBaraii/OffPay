package com.example.trialpaymentapp.auth

import android.util.Log
import com.example.trialpaymentapp.data.AppDatabase
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await // For kotlinx-coroutines-play-services, ensure this dependency is in your build.gradle
import kotlinx.coroutines.withContext

// Removed the unused 'local' property as it was causing a TODO() crash if accessed
// private val local: Any
//    get() {
//        TODO()
//    }

class AuthManager(
    private val firebaseAuth: FirebaseAuth,
    private val appDatabase: AppDatabase, // Assuming this is for local data, not directly used in setupNewUserFirestoreData
    private val firestore: FirebaseFirestore
) {
    // Example helper functions
    fun getCurrentUserId(): String? = firebaseAuth.currentUser?.uid
    fun isLoggedIn(): Boolean = firebaseAuth.currentUser != null

    suspend fun setupNewUserFirestoreData(user: FirebaseUser, displayName: String? = null) {
        // You might want a default display name or derive it from the email
        val finalDisplayName = displayName ?: user.email?.substringBefore('@')?.take(15) ?: "New User"

        // Define the data for the 'userCards' collection
        val userCardData = hashMapOf(
            "publicKeyPem" to "INITIAL_PUBLIC_KEY_PLACEHOLDER", // Replace with actual key generation logic if needed
            "keyId" to "INITIAL_KEY_ID_PLACEHOLDER",          // Replace with actual key ID logic if needed
            "displayName" to finalDisplayName,
            "updatedAt" to FieldValue.serverTimestamp()
            // Add any other fields you need for a new user card
        )

        // Define the data for the 'accounts' collection
        val accountData = hashMapOf(
            "balanceCents" to 0L, // Initial balance is 0
            "updatedAt" to FieldValue.serverTimestamp()
            // Add any other fields you need for a new user account
        )

        try {
            withContext(Dispatchers.IO) { // Perform Firestore operations on a background thread
                val userDocRef = firestore.collection("userCards").document(user.uid)
                val accountDocRef = firestore.collection("accounts").document(user.uid)

                // Use a Firestore batch write to set both documents atomically
                firestore.runBatch { batch ->
                    batch.set(userDocRef, userCardData)
                    batch.set(accountDocRef, accountData)
                }.await() // Use .await() if you have kotlinx-coroutines-play-services
                         // Otherwise, remove .await() and handle with addOnSuccessListener/addOnFailureListener

                Log.d("AuthManager", "Successfully created Firestore documents for new user: ${user.uid}")
            }
        } catch (e: Exception) {
            Log.e("AuthManager", "Error setting up Firestore data for new user: ${user.uid}", e)
            // Re-throw the exception so the calling coroutine in LoginScreen can catch it
            // and potentially display an error or sign out the user.
            throw e
        }
    }
}
