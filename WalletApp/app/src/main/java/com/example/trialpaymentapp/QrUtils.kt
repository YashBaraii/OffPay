package com.example.trialpaymentapp // Make sure this matches your app's package name

import android.graphics.Bitmap
import android.graphics.Color // Added this import
import android.util.Base64
import com.example.trialpaymentapp.data.Voucher
import com.example.trialpaymentapp.security.Keys
import com.google.zxing.BarcodeFormat
import com.google.zxing.common.BitMatrix
import com.google.zxing.MultiFormatWriter // Added this import
import com.google.zxing.WriterException // Added this import
import com.google.zxing.qrcode.QRCodeWriter
import java.nio.charset.StandardCharsets
import java.security.KeyFactory
import java.security.PublicKey
import java.security.Signature
import java.security.spec.X509EncodedKeySpec


import javax.crypto.Cipher

object QrUtils {
    fun generateQrCodeBitmap(text: String, width: Int = 200, height: Int = 200): Bitmap? { // Changed default size to 200 to match UI
        return try {
            val bitMatrix: BitMatrix = MultiFormatWriter().encode(
                text,
                BarcodeFormat.QR_CODE,
                width,
                height,
                null // You can pass encoding hints here if needed
            )
            val bmp = Bitmap.createBitmap(bitMatrix.width, bitMatrix.height, Bitmap.Config.RGB_565)
            for (x in 0 until bitMatrix.width) {
                for (y in 0 until bitMatrix.height) {
                    bmp.setPixel(x, y, if (bitMatrix[x, y]) Color.BLACK else Color.WHITE)
                }
            }
            bmp
        } catch (e: WriterException) {
            // Log the error or handle it more gracefully
            // For now, just printing the stack trace and returning null
            e.printStackTrace()
            null
        }
    }

    /** Parse OP1 QR string → Voucher ID (for demo, real app would parse full JSON) */
    fun decodeVoucher(qrText: String, senderPublicKeyPem: String): String {
        if (!qrText.startsWith("OP1:")) throw IllegalArgumentException("Invalid QR format")
        val parts = qrText.removePrefix("OP1:").split(".")
        if (parts.size != 3) throw IllegalArgumentException("Malformed QR code")

        val iv = Base64.decode(parts[0], Base64.URL_SAFE or Base64.NO_WRAP)
        val encrypted = Base64.decode(parts[1], Base64.URL_SAFE or Base64.NO_WRAP)
        val signature = Base64.decode(parts[2], Base64.URL_SAFE or Base64.NO_WRAP)

        // decrypt
        val decryptedBytes = Keys.decrypt(iv, encrypted)

        // verify signature
        val pubKey = loadPublicKey(senderPublicKeyPem)
        val sig = Signature.getInstance("SHA256withECDSA")
        sig.initVerify(pubKey)
        sig.update(decryptedBytes)
        val valid = sig.verify(signature)
        if (!valid) throw IllegalArgumentException("Invalid signature")

        return String(decryptedBytes, StandardCharsets.UTF_8)
    }

    /** Helper: convert PEM string to PublicKey */
    private fun loadPublicKey(pem: String): PublicKey {
        val clean = pem.replace("-----BEGIN PUBLIC KEY-----", "")
            .replace("-----END PUBLIC KEY-----", "")
            .replace("\\s".toRegex(), "") // Corrected regex for whitespace
        val decoded = Base64.decode(clean, Base64.DEFAULT)
        val spec = X509EncodedKeySpec(decoded)
        val kf = KeyFactory.getInstance("EC") // Assuming EC keys
        return kf.generatePublic(spec)
    }
}
