package com.example.trialpaymentapp.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.trialpaymentapp.data.Transaction
import com.example.trialpaymentapp.data.TransactionDao
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ReceiveMoneyViewModel(private val dao: TransactionDao) : ViewModel() {

    private val _scannedDataFeedback = MutableStateFlow<String?>(null)
    val scannedDataFeedback: StateFlow<String?> = _scannedDataFeedback.asStateFlow()

    // State to trigger QR code scanning in the UI
    private val _requestQrScan = MutableStateFlow(false)
    val requestQrScan: StateFlow<Boolean> = _requestQrScan.asStateFlow()

    /**
     * Call this method from the UI to signal that QR code scanning should begin.
     * The UI should observe [requestQrScan] and launch a scanner when true.
     */
    fun initiateQrScan() {
        _requestQrScan.value = true
    }

    /**
     * Call this method to reset the QR scan request state.
     * The UI should call this if the user cancels the scan.
     * The ViewModel also calls this internally after processing a scan result.
     */
    fun onScanHandled() {
        _requestQrScan.value = false
    }

    /**
     * Processes the raw string data obtained from the QR code scanner.
     * This function handles decryption and parsing of the data.
     */
    fun processScannedQrCode(qrData: String) {
        viewModelScope.launch {
            _scannedDataFeedback.value = "Processing scanned QR code..." // Provide immediate feedback

            // Step 1: Decrypt data. The QR code is expected to contain encrypted data.
            val decryptedData = decryptData(qrData)

            if (decryptedData == null) {
                // Feedback is updated by decryptData or remains generic if another error occurs.
                // If _scannedDataFeedback was not updated by decryptData, this generic message will be used.
                if (_scannedDataFeedback.value == "Processing scanned QR code...") {
                    _scannedDataFeedback.value = "Error: Failed to process QR code data. It might be corrupted or not in the expected format."
                }
                onScanHandled() // Reset scan request state
                return@launch
            }

            // Step 2: Parse the decrypted data into a Transaction object
            val parsedTransaction = parseQrDataToTransaction(decryptedData)

            if (parsedTransaction != null) {
                // Step 3: Record the transaction as "RECEIVED"
                val receivedTransaction = parsedTransaction.copy(
                    id = 0, // Let Room auto-generate the ID
                    type = "RECEIVED",
                    isSynced = false
                )
                dao.insertTransaction(receivedTransaction)
                _scannedDataFeedback.value = "Transaction Received! Amount: ${receivedTransaction.amount}, Details: ${receivedTransaction.details}"
            } else {
                _scannedDataFeedback.value = "Error: Invalid or unreadable QR code data after decryption."
            }
            onScanHandled() // Reset scan request state after processing
        }
    }

    /**
     * Decrypts the data from the QR code.
     * WARNING: THIS IS A PLACEHOLDER IMPLEMENTATION AND NOT SECURE.
     * You MUST replace this with a robust and secure decryption mechanism.
     *
     * @param encryptedData The raw data string from the QR code, expected to be encrypted.
     * @return The decrypted data as a string, or null if decryption fails or format is incorrect.
     */
    private fun decryptData(encryptedData: String): String? {
        // TODO: Replace with real, secure decryption logic.
        // For example, using AES:
        // try {
        //     return AESCipher.decrypt(encryptedData, getDecryptionKey())
        // } catch (e: Exception) {
        //     _scannedDataFeedback.value = "Decryption error: ${e.message}"
        //     println("Decryption failed: ${e.message}")
        //     return null
        // }

        println("Attempting to decrypt QR Data: $encryptedData")
        // Example placeholder: Assumes data is prefixed with "encrypted_"
        // This is NOT a secure method and is for demonstration only.
        if (encryptedData.startsWith("encrypted_")) {
            val decrypted = encryptedData.removePrefix("encrypted_")
            println("Placeholder decryption successful: $decrypted")
            return decrypted
        } else {
            val errorMessage = "Error: QR data does not appear to be encrypted in the expected format."
            println("Placeholder decryption failed: $errorMessage")
            _scannedDataFeedback.value = errorMessage // Provide specific feedback
            return null // Strict: if not in "encrypted_" format, consider it a failure.
        }
    }

    /**
     * Parses the decrypted QR data string into a Transaction object.
     *
     * @param decryptedData The decrypted data string.
     * @return A Transaction object if parsing is successful, or null otherwise.
     */
    private fun parseQrDataToTransaction(decryptedData: String): Transaction? {
        println("Parsing Decrypted QR Data: $decryptedData")
        try {
            // Expected format (example): "amount=100.00;senderTxId=sender-uuid-123;details=Payment for goods;timestamp=1678886400000"
            val parts = decryptedData.split(';').mapNotNull { part ->
                val keyValue = part.split('=', limit = 2)
                if (keyValue.size == 2) keyValue[0].trim() to keyValue[1].trim() else null
            }.toMap()

            val amount = parts["amount"]?.toDoubleOrNull()
            val senderTxId = parts["senderTxId"] // This will be the counterpartyId for the receiver
            val details = parts["details"] ?: "Received via QR scan" // Fallback if details field is missing
            val timestamp = parts["timestamp"]?.toLongOrNull() ?: System.currentTimeMillis()

            return if (amount != null && senderTxId != null) {
                Transaction(
                    type = "FROM_QR", // Temporary type, will be overridden to "RECEIVED" by processScannedQrCode
                    amount = amount,
                    timestamp = timestamp,
                    details = details,
                    counterpartyId = senderTxId, // ID of the sender or sender's transaction
                    isSynced = false
                )
            } else {
                println("Error parsing QR data: Required fields (amount, senderTxId) not found or invalid in '$decryptedData'. Parts found: $parts")
                null
            }
        } catch (e: Exception) {
            println("Exception during QR data parsing: $e")
            return null
        }
    }
}
