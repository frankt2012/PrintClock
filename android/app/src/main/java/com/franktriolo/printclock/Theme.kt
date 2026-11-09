package com.franktriolo.printclock

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val Navy = Color(0xFF0C1324)
private val NavySurface = Color(0xFF141E33)
private val Orange = Color(0xFFF5A623)
private val PaleBlue = Color(0xFF7FD1F0)

private val PrintClockColors = darkColorScheme(
    primary = Orange,
    onPrimary = Color(0xFF211600),
    primaryContainer = Color(0xFF3A2A08),
    onPrimaryContainer = Color(0xFFFFDDA0),
    secondary = PaleBlue,
    onSecondary = Color(0xFF00202B),
    background = Navy,
    onBackground = Color(0xFFE8EEF9),
    surface = NavySurface,
    onSurface = Color(0xFFE8EEF9),
    surfaceVariant = Color(0xFF1B2840),
    onSurfaceVariant = Color(0xFFB7C3D8),
    outline = Color(0xFF44536E),
    error = Color(0xFFFFB4AB)
)

@Composable
fun PrintClockTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = PrintClockColors,
        content = content
    )
}
