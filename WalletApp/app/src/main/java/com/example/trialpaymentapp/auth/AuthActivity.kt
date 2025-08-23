package com.example.trialpaymentapp.auth

import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Bundle
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AppCompatActivity
import com.example.trialpaymentapp.MainActivity
import com.example.trialpaymentapp.data.AppDatabase
import com.example.trialpaymentapp.data.UserProfile
import com.example.trialpaymentapp.security.Keys
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class AuthActivity : AppCompatActivity() {
    private val auth = FirebaseAuth.getInstance()
    private val fs = FirebaseFirestore.getInstance()

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (auth.currentUser == null) {
            auth.signInAnonymously()
                .addOnSuccessListener { onLoggedIn() }
                .addOnFailureListener {
                    it.printStackTrace()
                    onLoggedInOffline()
                }
        } else {
            onLoggedIn()
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun onLoggedIn() {
        CoroutineScope(Dispatchers.IO).launch {
            val uid = auth.currentUser!!.uid
            val db = AppDatabase.getDatabase(this@AuthActivity)

            // Ensure keys
            Keys.ensureKeys()
            val publicPem = Keys.publicKeyPem()

            // Save to local DB
            db.userProfileDao().upsert(
                UserProfile(
                    uid = uid,
                    displayName = "User-" + uid.takeLast(6),
                    keyId = "k1",
                    publicKeyPem = publicPem
                )
            )

            // Sync with Firebase if online
            if (isOnline()) {
                try {
                    val userCard = hashMapOf(
                        "publicKeyPem" to publicPem,
                        "keyId" to "k1",
                        "displayName" to "User-" + uid.takeLast(6),
                        "updatedAt" to FieldValue.serverTimestamp()
                    )
                    fs.collection("userCards").document(uid).set(userCard)

                    val account = hashMapOf(
                        "balanceCents" to 0L,
                        "updatedAt" to FieldValue.serverTimestamp()
                    )
                    fs.collection("accounts").document(uid).set(account)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            // Go to MainActivity
            launch(Dispatchers.Main) {
                startActivity(Intent(this@AuthActivity, MainActivity::class.java))
                finish()
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun onLoggedInOffline() {
        CoroutineScope(Dispatchers.IO).launch {
            val db = AppDatabase.getDatabase(this@AuthActivity)
            val userProfiles = db.userProfileDao().getAllUsers()

            // Ensure keys exist before using
            Keys.ensureKeys()
            val publicPem = Keys.publicKeyPem() // now safe

            val profile = if (userProfiles.isNotEmpty()) {
                userProfiles.first()
            } else {
                val offlineProfile = UserProfile(
                    uid = "offline-" + System.currentTimeMillis(),
                    displayName = "Offline User",
                    keyId = "k1",
                    publicKeyPem = publicPem
                )
                db.userProfileDao().upsert(offlineProfile)
                offlineProfile
            }

            launch(Dispatchers.Main) {
                startActivity(Intent(this@AuthActivity, MainActivity::class.java))
                finish()
            }
        }
    }

    private fun isOnline(): Boolean {
        val connectivityManager =
            getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network)
        return capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) ?: false
    }
}
