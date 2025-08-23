package com.example.trialpaymentapp.security

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import java.security.MessageDigest
import java.security.SecureRandom

class PinStore(context: Context) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val prefs = EncryptedSharedPreferences.create(
        context,
        "pin_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    private val random = SecureRandom()

    fun setPin(pin: String) {
        val salt = ByteArray(16).apply { random.nextBytes(this) }
        val hash = hashPin(pin, salt)
        prefs.edit()
            .putString("pin_hash", hash)
            .putString("pin_salt", salt.joinToString(","))
            .putInt("failed_attempts", 0)
            .apply()
    }

    fun verifyPin(pin: String): Boolean {
        val storedHash = prefs.getString("pin_hash", null) ?: return false
        val salt = prefs.getString("pin_salt", null)?.split(",")?.map { it.toByte() }?.toByteArray()
            ?: return false
        val failedAttempts = prefs.getInt("failed_attempts", 0)

        if (failedAttempts >= 5) return false // lockout after 5 tries

        val hash = hashPin(pin, salt)
        return if (hash == storedHash) {
            prefs.edit().putInt("failed_attempts", 0).apply()
            true
        } else {
            prefs.edit().putInt("failed_attempts", failedAttempts + 1).apply()
            false
        }
    }

    private fun hashPin(pin: String, salt: ByteArray): String {
        val md = MessageDigest.getInstance("SHA-256")
        md.update(salt)
        val digest = md.digest(pin.toByteArray())
        return digest.joinToString("") { "%02x".format(it) }
    }
}
