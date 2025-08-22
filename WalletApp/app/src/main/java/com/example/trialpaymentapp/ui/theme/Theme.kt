package com.example.trialpaymentapp.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

// Define the new Yellow and Black color scheme for dark theme
private val YellowBlackDarkColorScheme = darkColorScheme(
    primary = GoldYellow,       // Main interactive elements
    onPrimary = TextOnYellow,   // Text/icons on primary color
    secondary = LightYellow,    // Secondary interactive elements
    onSecondary = TextOnYellow, // Text/icons on secondary color
    tertiary = SubtleGray,      // Accents, less prominent elements
    onTertiary = TextOnDark,    // Text/icons on tertiary color
    background = DarkCharcoal,  // Screen background
    onBackground = TextOnDark,  // Text/icons on background
    surface = OffBlack,         // Surfaces like cards, dialogs
    onSurface = TextOnDark,     // Text/icons on surfaces
    error = PaleVioletRed,      // Standard error color
    onError = Color.White       // Text/icons on error color
)

// Define a corresponding light theme (optional, but good for consistency)
private val YellowBlackLightColorScheme = lightColorScheme(
    primary = GoldYellow,
    onPrimary = TextOnYellow,
    secondary = DarkCharcoal, // Using dark for secondary elements in light theme for contrast
    onSecondary = TextOnDark,
    tertiary = LightYellow,
    onTertiary = TextOnYellow,
    background = Color.White,   // Light background
    onBackground = OffBlack,    // Dark text on light background
    surface = Color(0xFFF5F5F5), // Light gray for surfaces
    onSurface = OffBlack,       // Dark text on light surfaces
    error = PaleVioletRed,
    onError = Color.White
)

@Composable
fun TrialPaymentAppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    // Dynamic color is available on Android 12+
    dynamicColor: Boolean = false, // Set to false to enforce your theme
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        // Use your custom yellow and black theme
        darkTheme -> YellowBlackDarkColorScheme
        else -> YellowBlackLightColorScheme // Or stick to YellowBlackDarkColorScheme if you only want dark
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography, // Assuming Typography.kt is defined
        content = content
    )
}
