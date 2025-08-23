package com.example.trialpaymentapp.security

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.annotation.RequiresApi
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import java.security.interfaces.ECPublicKey
import java.util.Base64

object Keys {
    private const val ANDROID_KEYSTORE = "AndroidKeyStore"
    private const val SIGNING_KEY_ALIAS = "trial_signing_key"
    private const val AES_KEY_ALIAS = "trial_aes_key"

    private const val ALIAS = "WALLET_EC_P256"

    // --- ECDSA Signing Keys ---
    fun generateSigningKeyPair(): KeyPair {
        val kpg = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_EC, ANDROID_KEYSTORE
        )
        kpg.initialize(
            KeyGenParameterSpec.Builder(
                SIGNING_KEY_ALIAS,
                KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
            )
                .setDigests(KeyProperties.DIGEST_SHA256)
                .build()
        )
        return kpg.generateKeyPair()
    }

    fun getSigningKeyPair(): KeyPair? {
        val ks = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        val entry = ks.getEntry(SIGNING_KEY_ALIAS, null) as? KeyStore.PrivateKeyEntry
        return entry?.let { KeyPair(it.certificate.publicKey, it.privateKey) }
    }

    fun signData(data: ByteArray): ByteArray {
        val keyPair = getSigningKeyPair() ?: generateSigningKeyPair()
        val signature = Signature.getInstance("SHA256withECDSA")
        signature.initSign(keyPair.private)
        signature.update(data)
        return signature.sign()
    }

    // --- AES Encryption Keys ---
    private fun generateAESKey(): SecretKey {
        val keyGen = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE
        )
        keyGen.init(
            KeyGenParameterSpec.Builder(
                AES_KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .build()
        )
        return keyGen.generateKey()
    }

    private fun getAESKey(): SecretKey {
        val ks = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        val entry = ks.getEntry(AES_KEY_ALIAS, null) as? KeyStore.SecretKeyEntry
        return entry?.secretKey ?: generateAESKey()
    }

    fun encrypt(data: ByteArray): Pair<ByteArray, ByteArray> {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, getAESKey())
        val iv = cipher.iv
        val ciphertext = cipher.doFinal(data)
        return Pair(iv, ciphertext)
    }

    fun decrypt(iv: ByteArray, ciphertext: ByteArray): ByteArray {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val spec = GCMParameterSpec(128, iv)
        cipher.init(Cipher.DECRYPT_MODE, getAESKey(), spec)
        return cipher.doFinal(ciphertext)
    }

    fun ensureKeys(): KeyPair {
        val ks = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        if (ks.containsAlias(ALIAS)) {
            val privateKey = ks.getKey(ALIAS, null)
            val publicKey = ks.getCertificate(ALIAS).publicKey
            return KeyPair(publicKey, privateKey as java.security.PrivateKey)
        }
        val kpg = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore"
        )
        val spec = KeyGenParameterSpec.Builder(
            ALIAS,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY or KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setAlgorithmParameterSpec(java.security.spec.ECGenParameterSpec("secp256r1"))
            .setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA512)
            .build()
        kpg.initialize(spec)
        return kpg.generateKeyPair()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    fun publicKeyPem(): String {
        val ks = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val pub = ks.getCertificate(ALIAS).publicKey as ECPublicKey
        val der = pub.encoded
        val b64 = Base64.getEncoder().encodeToString(der)
        return "-----BEGIN PUBLIC KEY-----\n$b64\n-----END PUBLIC KEY-----"
    }
}
