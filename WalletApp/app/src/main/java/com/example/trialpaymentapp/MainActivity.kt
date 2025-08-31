package com.example.trialpaymentapp

import android.content.Intent
// Removed: import android.graphics.Bitmap 
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.Image
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.trialpaymentapp.auth.AuthActivity
import com.example.trialpaymentapp.auth.AuthManager
import com.example.trialpaymentapp.data.Transaction
import com.example.trialpaymentapp.data.TransactionDao
import com.example.trialpaymentapp.data.AppDatabase // Added import
import com.example.trialpaymentapp.ui.screens.ReceiveMoneyScreen
import com.example.trialpaymentapp.ui.theme.TrialPaymentAppTheme
import com.example.trialpaymentapp.ui.viewmodel.BalanceViewModel
import com.example.trialpaymentapp.ui.viewmodel.ReceiveMoneyViewModel
import com.example.trialpaymentapp.ui.viewmodel.SendMoneyViewModel
import com.example.trialpaymentapp.ui.viewmodel.TransactionHistoryViewModel
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.firestore.FirebaseFirestore // Added import for PaymentApp.firestore
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.*
import androidx.compose.runtime.rememberCoroutineScope // Added for launching coroutine
import com.google.firebase.firestore.FieldValue // Potentially needed if AuthManager uses it directly here
import kotlinx.coroutines.launch // Added for launching coroutine

// --- Navigation States for MainActivity ---
sealed class MainScreenState {
    object Loading : MainScreenState()
    object Login : MainScreenState()
    object AppContent : MainScreenState()
}

sealed class AppScreen {
    object Home : AppScreen()
    object SendMoney : AppScreen()
    object ReceiveMoney : AppScreen()
    object TransactionHistory : AppScreen()
}



// --- ViewModel Factory ---
@Suppress("UNCHECKED_CAST")
class PaymentAppViewModelFactory(
    private val transactionDao: TransactionDao,
    private val authManager: AuthManager? = null // Made AuthManager optional if not all VMs need it
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return when {
            modelClass.isAssignableFrom(SendMoneyViewModel::class.java) ->
                SendMoneyViewModel(transactionDao) as T // Removed authManager
            modelClass.isAssignableFrom(ReceiveMoneyViewModel::class.java) ->
                ReceiveMoneyViewModel(transactionDao) as T
            modelClass.isAssignableFrom(TransactionHistoryViewModel::class.java) ->
                TransactionHistoryViewModel(transactionDao) as T // Removed authManager
            modelClass.isAssignableFrom(BalanceViewModel::class.java) ->
                BalanceViewModel(transactionDao) as T // Removed authManager
            else -> throw IllegalArgumentException("Unknown ViewModel class: ${modelClass.name}")
        }
    }
}


class MainActivity : ComponentActivity() {
    private lateinit var firebaseAuth: FirebaseAuth
    private lateinit var authManager: AuthManager
    private lateinit var appDatabase: AppDatabase
    private lateinit var firestore: FirebaseFirestore

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("MainActivity", "onCreate called")

        val paymentApp = application as PaymentApp
        appDatabase = paymentApp.database
        firestore = paymentApp.firestore
        firebaseAuth = FirebaseAuth.getInstance()
        authManager = AuthManager(firebaseAuth, appDatabase, firestore)


        setContent {
            TrialPaymentAppTheme {
                MainAppFlow(
                    authManager = authManager,
                    firebaseAuth = firebaseAuth,
                    transactionDao = appDatabase.transactionDao(),
                    application = paymentApp
                )
            }
        }
    }
}

@Composable
fun MainAppFlow(
    authManager: AuthManager,
    firebaseAuth: FirebaseAuth,
    transactionDao: TransactionDao,
    application: PaymentApp
) {
    var mainScreenState by remember { mutableStateOf<MainScreenState>(MainScreenState.Loading) }
    var currentFirebaseUser by remember { mutableStateOf(firebaseAuth.currentUser) }

    DisposableEffect(firebaseAuth) {
        val authListener = FirebaseAuth.AuthStateListener { auth ->
            val user = auth.currentUser
            Log.d("MainAppFlow", "Firebase AuthStateListener: User changed to ${user?.email}")
            currentFirebaseUser = user
            mainScreenState = if (user != null) MainScreenState.AppContent else MainScreenState.Login
        }
        firebaseAuth.addAuthStateListener(authListener)
        onDispose {
            Log.d("MainAppFlow", "Disposing AuthStateListener.")
            firebaseAuth.removeAuthStateListener(authListener)
        }
    }

    LaunchedEffect(Unit) {
        if (currentFirebaseUser == null) {
            mainScreenState = MainScreenState.Login
        } else {
            mainScreenState = MainScreenState.AppContent
        }
    }

    when (mainScreenState) {
        is MainScreenState.Loading -> LoadingScreen("Checking authentication state...")
        is MainScreenState.Login -> LoginScreen(
            firebaseAuth = firebaseAuth,
            authManager = authManager, 
            onLoginSuccess = { firebaseUser ->
                Log.d("MainAppFlow", "Login/Registration successful: ${firebaseUser.email}. Setting state to AppContent.")
                mainScreenState = MainScreenState.AppContent
            }
        )
        is MainScreenState.AppContent -> PaymentAppContent(
            transactionDao = transactionDao,
            authManager = authManager,
            firebaseAuth = firebaseAuth,
            application = application
        )
    }
}

@Composable
fun LoadingScreen(message: String = "Loading...") {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
            Spacer(modifier = Modifier.height(16.dp))
            Text(message, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onBackground)
        }
    }
}

@Composable
fun LoginScreen(
    firebaseAuth: FirebaseAuth,
    authManager: AuthManager, 
    onLoginSuccess: (FirebaseUser) -> Unit
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") } // For registration
    var error by remember { mutableStateOf<String?>(null) }
    var isLoading by remember { mutableStateOf(false) }
    var isRegisterMode by remember { mutableStateOf(false) } // To toggle between Login and Register
    val context = LocalContext.current
    val scope = rememberCoroutineScope() 

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp)
            .background(MaterialTheme.colorScheme.background),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            if (isRegisterMode) "Create an Account" else "Login to Your Account",
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.onBackground,
            modifier = Modifier.padding(bottom = 24.dp)
        )

        OutlinedTextField(
            value = email,
            onValueChange = { email = it.trim() },
            label = { Text("Email") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            colors = TextFieldDefaults.colors(
                focusedTextColor = MaterialTheme.colorScheme.onBackground,
                unfocusedTextColor = MaterialTheme.colorScheme.onBackground,
                focusedContainerColor = Color.Transparent,
                unfocusedContainerColor = Color.Transparent,
            )
        )
        Spacer(modifier = Modifier.height(12.dp))
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            colors = TextFieldDefaults.colors(
                 focusedTextColor = MaterialTheme.colorScheme.onBackground,
                unfocusedTextColor = MaterialTheme.colorScheme.onBackground,
                focusedContainerColor = Color.Transparent,
                unfocusedContainerColor = Color.Transparent,
            )
        )
        if (isRegisterMode) {
            Spacer(modifier = Modifier.height(12.dp))
            OutlinedTextField(
                value = confirmPassword,
                onValueChange = { confirmPassword = it },
                label = { Text("Confirm Password") },
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                colors = TextFieldDefaults.colors(
                    focusedTextColor = MaterialTheme.colorScheme.onBackground,
                    unfocusedTextColor = MaterialTheme.colorScheme.onBackground,
                    focusedContainerColor = Color.Transparent,
                    unfocusedContainerColor = Color.Transparent,
                )
            )
        }
        Spacer(modifier = Modifier.height(24.dp))

        Button(
            onClick = {
                error = null
                if (email.isBlank() || password.isBlank()) {
                    error = "Email and password cannot be empty."
                    return@Button
                }
                if (isRegisterMode && password.length < 6) {
                    error = "Password should be at least 6 characters."
                    return@Button
                }
                if (isRegisterMode && password != confirmPassword) {
                    error = "Passwords do not match."
                    return@Button
                }
                isLoading = true
                if (isRegisterMode) {
                    firebaseAuth.createUserWithEmailAndPassword(email, password)
                        .addOnCompleteListener { task ->
                            if (task.isSuccessful) {
                                val firebaseUser = task.result?.user
                                if (firebaseUser != null) {
                                    Log.d("LoginScreen", "Firebase registration successful for: $email")
                                    scope.launch {
                                        try {
                                            authManager.setupNewUserFirestoreData(firebaseUser)
                                            Log.d("LoginScreen", "Firestore data setup initiated for new user.")
                                            onLoginSuccess(firebaseUser) 
                                        } catch (e: Exception) {
                                            Log.e("LoginScreen", "Error setting up Firestore data", e)
                                            error = "Registration succeeded but failed to set up user profile: ${e.localizedMessage}"
                                            // Optionally sign out to prevent inconsistent state
                                            // firebaseUser.delete() // More aggressive, or firebaseAuth.signOut()
                                        } finally {
                                             isLoading = false
                                        }
                                    }
                                } else {
                                    isLoading = false
                                    error = "Registration successful but failed to get user."
                                    Log.w("LoginScreen", "Firebase registration ok, but user is null")
                                }
                            } else {
                                isLoading = false
                                error = task.exception?.localizedMessage ?: "Registration failed. Please try again."
                                Log.w("LoginScreen", "Firebase registration error:", task.exception)
                            }
                        }
                } else {
                    firebaseAuth.signInWithEmailAndPassword(email, password)
                        .addOnCompleteListener { task ->
                            isLoading = false
                            if (task.isSuccessful) {
                                Log.d("LoginScreen", "Firebase sign-in successful for: $email")
                                task.result?.user?.let(onLoginSuccess)
                            } else {
                                error = task.exception?.localizedMessage ?: "Login failed. Please check credentials."
                                Log.w("LoginScreen", "Firebase sign-in error:", task.exception)
                            }
                        }
                }
            },
            modifier = Modifier.fillMaxWidth().height(50.dp),
            enabled = !isLoading
        ) {
            if (isLoading) {
                CircularProgressIndicator(modifier = Modifier.size(24.dp), color = MaterialTheme.colorScheme.onPrimary)
            } else {
                Text(if (isRegisterMode) "Register" else "Login")
            }
        }

        TextButton(
            onClick = {
                isRegisterMode = !isRegisterMode
                error = null 
                Log.d("LoginScreen", "Switched to ${if (isRegisterMode) "Register" else "Login"} mode.")
            },
            modifier = Modifier.padding(top = 16.dp)
        ) {
            Text(
                if (isRegisterMode) "Already have an account? Login" else "No account? Register",
                color = MaterialTheme.colorScheme.primary
            )
        }

        if (!isRegisterMode) {
            TextButton(
                onClick = {
                    if (email.isBlank()) {
                        error = "Please enter your email to reset password."
                        return@TextButton
                    }
                    isLoading = true // To prevent multiple clicks
                    firebaseAuth.sendPasswordResetEmail(email)
                        .addOnCompleteListener { task ->
                            isLoading = false
                            if (task.isSuccessful) {
                                error = "Password reset email sent to $email." 
                                Log.d("LoginScreen", "Password reset email sent for $email.")
                            } else {
                                error = task.exception?.localizedMessage ?: "Failed to send password reset email."
                                Log.w("LoginScreen", "Error sending password reset email:", task.exception)
                            }
                        }
                },
                modifier = Modifier.padding(top = 8.dp),
                enabled = !isLoading 
            ) {
                Text("Forgot Password?", color = MaterialTheme.colorScheme.secondary)
            }
        }

        error?.let {
            Text(
                text = it,
                color = MaterialTheme.colorScheme.error,
                modifier = Modifier.padding(top = 12.dp),
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center
            )
        }
    }
}


@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaymentAppContent(
    transactionDao: TransactionDao,
    authManager: AuthManager,
    firebaseAuth: FirebaseAuth,
    application: PaymentApp
) {
    var currentAppScreen by remember { mutableStateOf<AppScreen>(AppScreen.Home) }

    val factory = remember {
        PaymentAppViewModelFactory(transactionDao, authManager)
    }

    val sendMoneyViewModel: SendMoneyViewModel = viewModel(factory = factory)
    val receiveMoneyViewModel: ReceiveMoneyViewModel = viewModel(factory = factory)
    val transactionHistoryViewModel: TransactionHistoryViewModel = viewModel(factory = factory)
    val balanceViewModel: BalanceViewModel = viewModel(factory = factory)

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        when (currentAppScreen) {
                            AppScreen.Home -> "Offline Pay"
                            AppScreen.SendMoney -> "Send Money"
                            AppScreen.ReceiveMoney -> "Receive Money"
                            AppScreen.TransactionHistory -> "Transaction History"
                        }
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface,
                    navigationIconContentColor = MaterialTheme.colorScheme.onSurface,
                    actionIconContentColor = MaterialTheme.colorScheme.onSurface
                ),
                navigationIcon = {
                    if (currentAppScreen != AppScreen.Home) {
                        IconButton(onClick = {
                            currentAppScreen = AppScreen.Home
                        }) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                        }
                    }
                },
                actions = {
                    when (currentAppScreen) {
                        AppScreen.TransactionHistory -> {
                            IconButton(onClick = { transactionHistoryViewModel.syncUnsyncedTransactions() }) {
                                Icon(Icons.Filled.Refresh, contentDescription = "Sync Transactions")
                            }
                        }
                        AppScreen.Home -> {
                             IconButton(onClick = { 
                                Log.d("PaymentAppContent", "Logout button clicked.")
                                firebaseAuth.signOut()
                            }) {
                                Icon(Icons.Default.ExitToApp, contentDescription = "Logout")
                            }
                        }
                        else -> { /* No actions for other screens */ }
                    }
                }
            )
        }
    ) { innerPadding ->
        Box(modifier = Modifier.padding(innerPadding).background(MaterialTheme.colorScheme.background)) {
            when (currentAppScreen) {
                AppScreen.Home -> HomeScreen(
                    balanceViewModel = balanceViewModel,
                    onSendMoneyClicked = { currentAppScreen = AppScreen.SendMoney },
                    onReceiveMoneyClicked = { currentAppScreen = AppScreen.ReceiveMoney },
                    onTransactionHistoryClicked = { currentAppScreen = AppScreen.TransactionHistory }
                )
                AppScreen.SendMoney -> SendMoneyScreen(sendMoneyViewModel)
                AppScreen.ReceiveMoney -> ReceiveMoneyScreen(receiveMoneyViewModel)
                AppScreen.TransactionHistory -> TransactionHistoryScreen(transactionHistoryViewModel)
            }
        }
    }
}

@Composable
fun HomeScreen(
    balanceViewModel: BalanceViewModel,
    onSendMoneyClicked: () -> Unit,
    onReceiveMoneyClicked: () -> Unit,
    onTransactionHistoryClicked: () -> Unit,
    modifier: Modifier = Modifier
) {
    val balance by balanceViewModel.currentBalance.collectAsState()

    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp)
            .background(MaterialTheme.colorScheme.background),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Good Evening", 
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onBackground,
            modifier = Modifier.align(Alignment.Start)
        )
        Text(
            text = "Welcome Back!", 
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onBackground,
            modifier = Modifier
                .align(Alignment.Start)
                .padding(bottom = 24.dp)
        )

        BalanceCard(
            balance = balance,
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 32.dp)
        )

        ElevatedButton(
            onClick = onSendMoneyClicked,
            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp).height(56.dp)
        ) { Text("Send Money", style = MaterialTheme.typography.labelLarge) }

        ElevatedButton(
            onClick = onReceiveMoneyClicked,
            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp).height(56.dp)
        ) { Text("Receive Money", style = MaterialTheme.typography.labelLarge) }

        ElevatedButton(
            onClick = onTransactionHistoryClicked,
            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp).height(56.dp)
        ) { Text("View Transactions", style = MaterialTheme.typography.labelLarge) }
    }
}

@Composable
fun BalanceCard(
    balance: Double,
    modifier: Modifier = Modifier
) {
    val currencyFormat = remember { NumberFormat.getCurrencyInstance(Locale("en", "IN")) }
    Card(
        modifier = modifier.shadow(elevation = 8.dp, shape = RoundedCornerShape(16.dp)),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Box(modifier = Modifier.padding(16.dp)) {
            Column(modifier = Modifier.fillMaxWidth()) {
                Text("Available Balance", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface)
                Text(
                    text = currencyFormat.format(balance),
                    style = MaterialTheme.typography.displaySmall.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
                Text("Last sync: Just now", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f))
            }
            Text( 
                text = "Online", 
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .background(color = Color.Green.copy(alpha = 0.3f), shape = RoundedCornerShape(4.dp))
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
            .background(MaterialTheme.colorScheme.background),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        OutlinedTextField(
            value = amount,
            onValueChange = { viewModel.updateAmount(it) },
            label = { Text("Amount") },
            modifier = Modifier.fillMaxWidth(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
             colors = TextFieldDefaults.colors(
                focusedTextColor = MaterialTheme.colorScheme.onBackground,
                unfocusedTextColor = MaterialTheme.colorScheme.onBackground,
                focusedContainerColor = Color.Transparent,
                unfocusedContainerColor = Color.Transparent,
            )
        )
        OutlinedTextField(
            value = pin,
            onValueChange = { viewModel.updatePin(it) },
            label = { Text("PIN") },
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
            modifier = Modifier.fillMaxWidth(),
             colors = TextFieldDefaults.colors(
                focusedTextColor = MaterialTheme.colorScheme.onBackground,
                unfocusedTextColor = MaterialTheme.colorScheme.onBackground,
                focusedContainerColor = Color.Transparent,
                unfocusedContainerColor = Color.Transparent,
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
            Text("Scan QR Code:", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onBackground, modifier = Modifier.align(Alignment.CenterHorizontally))
            Spacer(modifier = Modifier.height(8.dp))

            val qrBitmap: android.graphics.Bitmap? by remember(data) { // Added android.graphics.Bitmap here
                derivedStateOf {
                    try { QrUtils.generateQrCodeBitmap(text = data, width = 200, height = 200) } catch (e: Exception) { Log.e("SendMoneyScreen", "Error generating QR", e); null }
                }
            }

            if (qrBitmap != null) {
                Image(
                    bitmap = qrBitmap!!.asImageBitmap(),
                    contentDescription = "Transaction QR Code",
                    modifier = Modifier.size(200.dp).align(Alignment.CenterHorizontally).border(BorderStroke(1.dp, MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)))
                )
            } else {
                Box(
                    modifier = Modifier.size(200.dp).border(BorderStroke(1.dp, MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f))).align(Alignment.CenterHorizontally).padding(16.dp),
                    contentAlignment = Alignment.Center
                ) { Text("Generating QR Code...", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onBackground) }
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text("Encrypted Data:", style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.onBackground, modifier = Modifier.align(Alignment.CenterHorizontally))
            Text(
                text = data,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp).align(Alignment.CenterHorizontally),
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.7f),
                textAlign = TextAlign.Center, maxLines = 3, overflow = TextOverflow.Ellipsis
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
            modifier = Modifier.fillMaxSize().padding(16.dp).background(MaterialTheme.colorScheme.background),
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
                style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )
            Text("Details: ${transaction.details}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f))
            Text("Synced: ${transaction.isSynced}", style = MaterialTheme.typography.bodySmall, color = if (transaction.isSynced) Color.Green.copy(alpha = 0.7f) else MaterialTheme.colorScheme.error)
        }
    }
}

// --- Previews ---
@Preview(showBackground = true, name = "Loading Screen Preview")
@Composable
fun LoadingScreenPreview() {
    TrialPaymentAppTheme(darkTheme = true) {
        LoadingScreen("Authenticating...")
    }
}

@Preview(showBackground = true, name = "Login Screen Preview Dark")
@Composable
fun LoginScreenPreviewDark() {
    TrialPaymentAppTheme(darkTheme = true) {
        // For preview, it's best to mock FirebaseAuth and AuthManager
        // This is a simplified version for preview.
        val mockAuth = FirebaseAuth.getInstance() // Or a mocked instance
        val mockAppDatabase = AppDatabase.getDatabase(LocalContext.current) // simplified for preview
        val mockAuthManager = AuthManager(mockAuth, mockAppDatabase, FirebaseFirestore.getInstance())
        LoginScreen(mockAuth,mockAuthManager, {}) 
    }
}

@Preview(showBackground = true, name = "HomeScreen Preview")
@Composable
fun HomeScreenPreview() {
    TrialPaymentAppTheme(darkTheme = true) {
        val mockAuth = FirebaseAuth.getInstance()
        val mockAppDatabase = AppDatabase.getDatabase(LocalContext.current)
        val mockAuthManager = AuthManager(mockAuth, mockAppDatabase, FirebaseFirestore.getInstance())
        val factory = PaymentAppViewModelFactory(mockAppDatabase.transactionDao(), mockAuthManager)
        val dummyBalanceViewModel: BalanceViewModel = viewModel(factory = factory) 
        HomeScreen(
            balanceViewModel = dummyBalanceViewModel,
            onSendMoneyClicked = {},
            onReceiveMoneyClicked = {},
            onTransactionHistoryClicked = {}
        )
    }
}
