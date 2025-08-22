package com.example.trialpaymentapp

import android.graphics.Bitmap // Required for qrBitmap state
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.Image // Required for Image composable
import androidx.compose.foundation.BorderStroke // Required for BorderStroke class
import androidx.compose.foundation.background
import androidx.compose.foundation.border // Required for border on Image/Box
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
// import androidx.compose.ui.graphics.Brush // No longer using custom gradient for BalanceCard
import androidx.compose.ui.graphics.Color // Required for BorderStroke color
import androidx.compose.ui.graphics.asImageBitmap // Required to convert Bitmap to ImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign // For text alignment
import androidx.compose.ui.text.style.TextOverflow // For text overflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.trialpaymentapp.data.Transaction
import com.example.trialpaymentapp.data.TransactionDao
// Remove DeepBlue and SkyBlue if no longer used directly
// import com.example.trialpaymentapp.ui.theme.DeepBlue
// import com.example.trialpaymentapp.ui.theme.SkyBlue
import com.example.trialpaymentapp.ui.theme.TrialPaymentAppTheme
import com.example.trialpaymentapp.ui.viewmodel.BalanceViewModel // Import BalanceViewModel
import com.example.trialpaymentapp.ui.viewmodel.ReceiveMoneyViewModel
import com.example.trialpaymentapp.ui.viewmodel.SendMoneyViewModel
import com.example.trialpaymentapp.ui.viewmodel.TransactionHistoryViewModel
// Ensure QrUtils is imported
import com.example.trialpaymentapp.QrUtils
// Import the new ReceiveMoneyScreen
import com.example.trialpaymentapp.ui.screens.ReceiveMoneyScreen

import java.text.SimpleDateFormat
import java.util.*
import java.text.NumberFormat // For currency formatting

// Sealed class to represent different screens
sealed class Screen {
    object Home : Screen()
    object SendMoney : Screen()
    object ReceiveMoney : Screen()
    object TransactionHistory : Screen()
}

// Simple ViewModelFactory for ViewModels with TransactionDao dependency
@Suppress("UNCHECKED_CAST")
class BaseViewModelFactory(private val transactionDao: TransactionDao) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return when {
            modelClass.isAssignableFrom(SendMoneyViewModel::class.java) -> {
                SendMoneyViewModel(transactionDao) as T
            }
            modelClass.isAssignableFrom(ReceiveMoneyViewModel::class.java) -> {
                ReceiveMoneyViewModel(transactionDao) as T
            }
            modelClass.isAssignableFrom(TransactionHistoryViewModel::class.java) -> {
                TransactionHistoryViewModel(transactionDao) as T
            }
            modelClass.isAssignableFrom(BalanceViewModel::class.java) -> { // Added BalanceViewModel
                BalanceViewModel(transactionDao) as T
            }
            else -> throw IllegalArgumentException("Unknown ViewModel class: ${modelClass.name}")
        }
    }
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            TrialPaymentAppTheme {
                PaymentAppContent()
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaymentAppContent() {
    var currentScreen by remember { mutableStateOf<Screen>(Screen.Home) }
    val context = LocalContext.current
    val dao = (context.applicationContext as? com.example.trialpaymentapp.PaymentApp)?.database?.transactionDao()

    if (dao == null) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("Error: Could not initialize database. App functionality will be limited.")
        }
        return
    }

    val factory = BaseViewModelFactory(dao)

    val sendMoneyViewModel: SendMoneyViewModel = viewModel(factory = factory)
    val receiveMoneyViewModel: ReceiveMoneyViewModel = viewModel(factory = factory)
    val transactionHistoryViewModel: TransactionHistoryViewModel = viewModel(factory = factory)
    val balanceViewModel: BalanceViewModel = viewModel(factory = factory) // Instantiate BalanceViewModel

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        when (currentScreen) {
                            Screen.Home -> "Offline Pay"
                            Screen.SendMoney -> "Send Money"
                            Screen.ReceiveMoney -> "Receive Money"
                            Screen.TransactionHistory -> "Transaction History"
                        }
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface, // Use theme surface color
                    titleContentColor = MaterialTheme.colorScheme.onSurface, // Use theme onSurface for title
                    navigationIconContentColor = MaterialTheme.colorScheme.onSurface,
                    actionIconContentColor = MaterialTheme.colorScheme.onSurface
                ),
                navigationIcon = {
                    if (currentScreen != Screen.Home) {
                        IconButton(onClick = {
                            if (currentScreen == Screen.SendMoney) {
                                sendMoneyViewModel.clearQrData()
                            }
                            currentScreen = Screen.Home
                        }) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                        }
                    }
                },
                actions = {
                    if (currentScreen == Screen.TransactionHistory) {
                        IconButton(onClick = { transactionHistoryViewModel.syncUnsyncedTransactions() }) {
                            Icon(Icons.Filled.Refresh, contentDescription = "Sync Transactions")
                        }
                    }
                }
            )
        }
    ) { innerPadding ->
        Box(modifier = Modifier.padding(innerPadding).background(MaterialTheme.colorScheme.background)) {
            when (currentScreen) {
                Screen.Home -> HomeScreen(
                    balanceViewModel = balanceViewModel, // Pass BalanceViewModel
                    onSendMoneyClicked = { currentScreen = Screen.SendMoney },
                    onReceiveMoneyClicked = { currentScreen = Screen.ReceiveMoney },
                    onTransactionHistoryClicked = { currentScreen = Screen.TransactionHistory }
                )
                Screen.SendMoney -> SendMoneyScreen(sendMoneyViewModel)
                Screen.ReceiveMoney -> ReceiveMoneyScreen(receiveMoneyViewModel) // This now calls the imported version
                Screen.TransactionHistory -> TransactionHistoryScreen(transactionHistoryViewModel)
            }
        }
    }
}

@Composable
fun HomeScreen(
    balanceViewModel: BalanceViewModel, // Accept BalanceViewModel
    onSendMoneyClicked: () -> Unit,
    onReceiveMoneyClicked: () -> Unit,
    onTransactionHistoryClicked: () -> Unit,
    modifier: Modifier = Modifier
) {
    val balance by balanceViewModel.currentBalance.collectAsState() // Collect balance state

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Greeting Text
        Text(
            text = "Good Evening",
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onBackground, // Use theme color
            modifier = Modifier.align(Alignment.Start)
        )
        Text(
            text = "Welcome",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onBackground, // Use theme color
            modifier = Modifier
                .align(Alignment.Start)
                .padding(bottom = 24.dp)
        )

        // Balance Card
        BalanceCard(
            balance = balance, // Pass the collected balance
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 32.dp)
        )

        // Action Buttons - ElevatedButton should pick up theme colors by default
        ElevatedButton(
            onClick = onSendMoneyClicked,
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp)
                .height(56.dp)
        ) {
            Text("Send Money", style = MaterialTheme.typography.labelLarge)
        }
        ElevatedButton(
            onClick = onReceiveMoneyClicked,
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp)
                .height(56.dp)
        ) {
            Text("Receive Money", style = MaterialTheme.typography.labelLarge)
        }
        ElevatedButton(
            onClick = onTransactionHistoryClicked,
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp)
                .height(56.dp)
        ) {
            Text("View Transactions", style = MaterialTheme.typography.labelLarge)
        }
    }
}

@Composable
fun BalanceCard(
    balance: Double, // Accept dynamic balance
    modifier: Modifier = Modifier
) {
    val currencyFormat = remember { NumberFormat.getCurrencyInstance(Locale("en", "IN")) }

    Card(
        modifier = modifier
            .shadow(elevation = 8.dp, shape = RoundedCornerShape(16.dp)),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface // Use theme surface color
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp) // Shadow is handled by modifier.shadow
    ) {
        Box(
            modifier = Modifier
                // .background(MaterialTheme.colorScheme.surface) // Card does this
                .padding(16.dp)
        ) {
            Column(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = "Available Balance",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface // Use theme color
                )
                Text(
                    text = currencyFormat.format(balance),
                    style = MaterialTheme.typography.displaySmall.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.primary, // Use theme primary for emphasis
                    modifier = Modifier.padding(vertical = 8.dp)
                )
                Text(
                    text = "Last sync: Just now",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f) // Slightly dimmed
                )
            }
            Text(
                text = "Online",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurface, // Or a specific status color
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .background(
                        // Consider a theme-appropriate color or keep green for universal meaning
                        color = Color.Green.copy(alpha = 0.3f), 
                        shape = RoundedCornerShape(4.dp)
                    )
                    .padding(horizontal = 8.dp, vertical = 4.dp)
            )
        }
    }
}


@Composable
fun SendMoneyScreen(viewModel: SendMoneyViewModel) {
    val amount by viewModel.amountInput.collectAsState()
    val pin by viewModel.pinInput.collectAsState()
    val encryptedQrString by viewModel.encryptedQrString.collectAsState()
    val transactionFeedback by viewModel.transactionFeedback.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .background(MaterialTheme.colorScheme.background), // Ensure screen background uses theme
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp) 
    ) {
        OutlinedTextField(
            value = amount,
            onValueChange = { viewModel.updateAmount(it) },
            label = { Text("Amount") },
            modifier = Modifier.fillMaxWidth(),
            colors = TextFieldDefaults.colors(
                focusedTextColor = MaterialTheme.colorScheme.onBackground,
                unfocusedTextColor = MaterialTheme.colorScheme.onBackground,
                focusedContainerColor = Color.Transparent,
                unfocusedContainerColor = Color.Transparent,
                disabledContainerColor = Color.Transparent,
                cursorColor = MaterialTheme.colorScheme.primary,
                focusedIndicatorColor = MaterialTheme.colorScheme.primary,
                unfocusedIndicatorColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f),
                focusedLabelColor = MaterialTheme.colorScheme.primary,
                unfocusedLabelColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )
        )
        OutlinedTextField(
            value = pin,
            onValueChange = { viewModel.updatePin(it) },
            label = { Text("PIN") },
            visualTransformation = PasswordVisualTransformation(),
            modifier = Modifier.fillMaxWidth(),
            colors = TextFieldDefaults.colors(
                focusedTextColor = MaterialTheme.colorScheme.onBackground,
                unfocusedTextColor = MaterialTheme.colorScheme.onBackground,
                focusedContainerColor = Color.Transparent,
                unfocusedContainerColor = Color.Transparent,
                disabledContainerColor = Color.Transparent,
                cursorColor = MaterialTheme.colorScheme.primary,
                focusedIndicatorColor = MaterialTheme.colorScheme.primary,
                unfocusedIndicatorColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f),
                focusedLabelColor = MaterialTheme.colorScheme.primary,
                unfocusedLabelColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )
        )
        ElevatedButton(
            onClick = { viewModel.prepareTransactionAndGenerateQr() },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Generate QR & Save Transaction")
        }

        transactionFeedback?.let { feedback ->
            Text(
                text = feedback,
                modifier = Modifier.padding(vertical = 8.dp), 
                color = if (feedback.startsWith("Error:")) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary,
                textAlign = TextAlign.Center
            )
        }

        encryptedQrString?.let { data ->
            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Scan QR Code:",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onBackground,
                modifier = Modifier.align(Alignment.CenterHorizontally)
            )
            Spacer(modifier = Modifier.height(8.dp))

            val qrBitmap: Bitmap? by remember(data) { 
                derivedStateOf {
                    QrUtils.generateQrCodeBitmap(text = data, width = 200, height = 200)
                }
            }

            if (qrBitmap != null) {
                Image(
                    bitmap = qrBitmap!!.asImageBitmap(),
                    contentDescription = "Transaction QR Code",
                    modifier = Modifier
                        .size(200.dp)
                        .align(Alignment.CenterHorizontally)
                        .border(BorderStroke(1.dp, MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)))
                )
            } else {
                Box(
                    modifier = Modifier
                        .size(200.dp)
                        .border(BorderStroke(1.dp, MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f)))
                        .align(Alignment.CenterHorizontally)
                        .padding(16.dp), 
                    contentAlignment = Alignment.Center
                ) {
                    Text("Generating QR Code...", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onBackground)
                }
            }

            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Encrypted Data:",
                style = MaterialTheme.typography.titleSmall, 
                color = MaterialTheme.colorScheme.onBackground,
                modifier = Modifier.align(Alignment.CenterHorizontally)
            )
            Text(
                text = data,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 4.dp)
                    .align(Alignment.CenterHorizontally),
                style = MaterialTheme.typography.bodySmall, 
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f),
                textAlign = TextAlign.Center,
                maxLines = 3, 
                overflow = TextOverflow.Ellipsis 
            )
        }
    }
}


@Composable
fun TransactionHistoryScreen(viewModel: TransactionHistoryViewModel) {
    val transactions by viewModel.transactions.collectAsState(initial = emptyList())

    if (transactions.isEmpty()) {
        Box(modifier = Modifier.fillMaxSize().padding(16.dp).background(MaterialTheme.colorScheme.background), contentAlignment = Alignment.Center) {
            Text("No transactions yet.", color = MaterialTheme.colorScheme.onBackground)
        }
    } else {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
                .background(MaterialTheme.colorScheme.background),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(transactions) { transaction ->
                TransactionListItem(transaction = transaction)
            }
        }
    }
}

@Composable
fun TransactionListItem(transaction: Transaction) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Type: ${transaction.type}", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
            Text("Amount: ${transaction.amount}", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurface)
            Text(
                "Date: ${SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault()).format(Date(transaction.timestamp))}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )
            Text("Details: ${transaction.details}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f))
            Text("Synced: ${transaction.isSynced}", style = MaterialTheme.typography.bodySmall, color = if (transaction.isSynced) Color.Green else MaterialTheme.colorScheme.error)
        }
    }
}

@Preview(showBackground = true)
@Composable
fun HomeScreenPreview() {
    TrialPaymentAppTheme(darkTheme = true) {
        HomeScreen(
            balanceViewModel = viewModel(), 
            onSendMoneyClicked = {},
            onReceiveMoneyClicked = {},
            onTransactionHistoryClicked = {}
        )
    }
}


@Preview(showBackground = true, name = "Balance Card Preview Dark")
@Composable
fun BalanceCardPreviewDark() {
    TrialPaymentAppTheme(darkTheme = true) {
        BalanceCard(balance = 12345.67)
    }
}
@Preview(showBackground = true, name = "Balance Card Preview Light")
@Composable
fun BalanceCardPreviewLight() {
    TrialPaymentAppTheme(darkTheme = false) {
        BalanceCard(balance = 12345.67)
    }
}

@Preview(showBackground = true)
@Composable
fun SendMoneyScreenPreview() {
    TrialPaymentAppTheme(darkTheme = true) {
        SendMoneyScreen(viewModel()) // This viewModel() might need a factory in previews
    }
}

@Preview(showBackground = true)
@Composable
fun TransactionHistoryScreenPreview() {
    TrialPaymentAppTheme(darkTheme = true) {
        val previewTransactions = listOf(
            Transaction(0, "SENT", 100.0, System.currentTimeMillis(), "details1", "receiver1", false),
            Transaction(0, "RECEIVED", 50.0, System.currentTimeMillis() - 100000, "details2", "sender1", true)
        )
        LazyColumn(modifier = Modifier.padding(16.dp)) {
            items(previewTransactions) { transaction ->
                TransactionListItem(transaction)
            }
        }
    }
}

