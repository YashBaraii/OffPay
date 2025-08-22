package com.example.trialpaymentapp.ui.screens

import android.Manifest
import android.content.pm.PackageManager
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.trialpaymentapp.ui.viewmodel.ReceiveMoneyViewModel
import com.journeyapps.barcodescanner.ScanContract
import com.journeyapps.barcodescanner.ScanOptions

@Composable
fun ReceiveMoneyScreen(
    receiveMoneyViewModel: ReceiveMoneyViewModel = viewModel()
) {
    val context = LocalContext.current
    val requestQrScan by receiveMoneyViewModel.requestQrScan.collectAsState()
    val scannedDataFeedback by receiveMoneyViewModel.scannedDataFeedback.collectAsState()

    // Launcher for the QR code scanner
    val qrScannerLauncher = rememberLauncherForActivityResult(ScanContract()) { result ->
        if (result.contents != null) {
            // QR code was successfully scanned
            receiveMoneyViewModel.processScannedQrCode(result.contents)
        } else {
            // Scan was cancelled by the user or failed
            Toast.makeText(context, "Scan cancelled", Toast.LENGTH_LONG).show()
            receiveMoneyViewModel.onScanHandled() // Reset ViewModel state
        }
    }

    // Launcher for requesting camera permission
    val requestPermissionLauncher = rememberLauncherForActivityResult(
        androidx.activity.result.contract.ActivityResultContracts.RequestPermission()
    ) { isGranted: Boolean ->
        if (isGranted) {
            // Permission is granted, configure and launch the scanner
            val options = ScanOptions().apply {
                setDesiredBarcodeFormats(ScanOptions.QR_CODE)
                setPrompt("Scan payer's QR code")
                setCameraId(0) // Use a specific camera of the device (0 for rear)
                setBeepEnabled(true)
                setBarcodeImageEnabled(true)
            }
            qrScannerLauncher.launch(options)
        } else {
            // Permission denied
            Toast.makeText(context, "Camera permission is required to scan QR codes", Toast.LENGTH_LONG).show()
            receiveMoneyViewModel.onScanHandled() // Reset ViewModel state as scan cannot proceed
        }
    }

    // Effect to trigger permission check and scanner launch when ViewModel requests it
    LaunchedEffect(requestQrScan) {
        if (requestQrScan) {
            when (PackageManager.PERMISSION_GRANTED) {
                ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) -> {
                    // Permission is already granted, launch the scanner
                    val options = ScanOptions().apply {
                        setDesiredBarcodeFormats(ScanOptions.QR_CODE)
                        setPrompt("Scan payer's QR code")
                        setCameraId(0)
                        setBeepEnabled(true)
                        setBarcodeImageEnabled(true)
                    }
                    qrScannerLauncher.launch(options)
                }
                else -> {
                    // Permission is not granted, request it
                    requestPermissionLauncher.launch(Manifest.permission.CAMERA)
                }
            }
            // onScanHandled is called by the launchers' callbacks now
        }
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Button(
            onClick = {
                receiveMoneyViewModel.initiateQrScan()
            },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Scan QR Code to Receive Money")
        }

        Spacer(modifier = Modifier.height(16.dp))

        scannedDataFeedback?.let { feedback ->
            Text(
                text = feedback,
                style = if (feedback.startsWith("Error:")) MaterialTheme.typography.bodyLarge.copy(color = MaterialTheme.colorScheme.error)
                        else MaterialTheme.typography.bodyLarge
            )
        }
    }
}
