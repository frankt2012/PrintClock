package com.franktriolo.printclock

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AssistChip
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.viewmodel.compose.viewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive

private data class Preset(val label: String, val hours: Int, val minutes: Int)

private val presets = listOf(
    Preset("30m", 0, 30),
    Preset("1h", 1, 0),
    Preset("2h", 2, 0),
    Preset("4h", 4, 0),
    Preset("8h", 8, 0)
)

@Composable
fun PrintClockScreen(viewModel: PrintClockViewModel = viewModel()) {
    val context = LocalContext.current
    var nowMillis by remember { mutableLongStateOf(System.currentTimeMillis()) }

    LaunchedEffect(Unit) {
        while (isActive) {
            nowMillis = System.currentTimeMillis()
            delay(1_000)
        }
    }

    var permissionRequested by rememberSaveable { mutableStateOf(false) }
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { }

    LaunchedEffect(viewModel.active) {
        if (!viewModel.active) return@LaunchedEffect
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            !permissionRequested &&
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            permissionRequested = true
            permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .systemBarsPadding()
                .padding(horizontal = 20.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Header()
            DurationCard(viewModel)
            StartCard(viewModel)
            ResultCard(viewModel, nowMillis)
            Text(
                text = "You'll get a notification when the print time reaches zero.",
                fontSize = 12.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 2.dp)
            )
        }
    }
}

@Composable
private fun Header() {
    Row(verticalAlignment = Alignment.CenterVertically) {
        androidx.compose.foundation.Image(
            painter = painterResource(R.drawable.app_icon),
            contentDescription = null,
            modifier = Modifier
                .size(50.dp)
                .clip(RoundedCornerShape(13.dp))
        )
        Spacer(Modifier.width(12.dp))
        Column {
            Text(
                text = "PrintClock",
                fontSize = 23.sp,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                text = "Know exactly when your 3D print finishes.",
                fontSize = 12.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun DurationCard(viewModel: PrintClockViewModel) {
    SectionCard {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Print time", fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.weight(1f))
            Text(
                text = if (viewModel.hasDuration) {
                    PrintTime.durationLabel(viewModel.hours, viewModel.minutes)
                } else {
                    "From your slicer"
                },
                fontSize = 13.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            NumberField(
                value = viewModel.hours,
                label = "Hours",
                suffix = "h",
                modifier = Modifier.weight(1f),
                onValueChange = viewModel::updateHours
            )
            NumberField(
                value = viewModel.minutes,
                label = "Minutes",
                suffix = "m",
                modifier = Modifier.weight(1f),
                onValueChange = viewModel::updateMinutes
            )
        }

        Row(
            modifier = Modifier.horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            presets.forEach { preset ->
                AssistChip(
                    onClick = {
                        viewModel.setDuration(preset.hours, preset.minutes)
                    },
                    label = { Text(preset.label) }
                )
            }
            if (viewModel.hasDuration) {
                TextButton(onClick = viewModel::clear) {
                    Text("Clear")
                }
            }
        }
    }
}

@Composable
private fun NumberField(
    value: Int,
    label: String,
    suffix: String,
    modifier: Modifier = Modifier,
    onValueChange: (Int) -> Unit
) {
    var fieldValue by remember { mutableStateOf(TextFieldValue(value.toString())) }
    var focused by remember { mutableStateOf(false) }

    LaunchedEffect(value) {
        if (!focused) {
            val updated = value.toString()
            if (fieldValue.text != updated) {
                fieldValue = TextFieldValue(updated)
            }
        }
    }

    OutlinedTextField(
        value = fieldValue,
        onValueChange = { newValue ->
            val digits = newValue.text.filter { it.isDigit() }.take(3)
            onValueChange(digits.toIntOrNull() ?: 0)
            fieldValue = newValue.copy(
                text = digits,
                selection = TextRange(minOf(newValue.selection.end, digits.length))
            )
        },
        label = { Text(label) },
        trailingIcon = {
            Text(suffix, color = MaterialTheme.colorScheme.onSurfaceVariant)
        },
        singleLine = true,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
        textStyle = LocalTextStyle.current.copy(
            fontSize = 28.sp,
            fontWeight = FontWeight.SemiBold,
            fontFamily = FontFamily.Monospace,
            textAlign = TextAlign.End
        ),
        shape = RoundedCornerShape(12.dp),
        modifier = modifier.onFocusChanged { state ->
            if (state.isFocused && !focused) {
                fieldValue = fieldValue.copy(
                    selection = TextRange(0, fieldValue.text.length)
                )
            }
            focused = state.isFocused
        }
    )
}

@Composable
private fun StartCard(viewModel: PrintClockViewModel) {
    SectionCard {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Start", fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.weight(1f))
            Text(
                text = "Now",
                fontSize = 13.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = if (viewModel.hasDuration) {
                    "Started at ${PrintTime.clockLabel(viewModel.startMillis)}"
                } else {
                    "Ready when you are"
                },
                fontSize = 13.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.weight(1f))
            TextButton(
                onClick = viewModel::resetToNow,
                enabled = viewModel.hasDuration
            ) {
                Text("Reset to now")
            }
        }
    }
}

@Composable
private fun ResultCard(viewModel: PrintClockViewModel, nowMillis: Long) {
    val hasDuration = viewModel.hasDuration
    val finishMillis = viewModel.finishMillis
    val remaining = finishMillis - nowMillis
    val progress = if (hasDuration) {
        PrintTime.progress(viewModel.startMillis, finishMillis, nowMillis)
    } else {
        0f
    }
    val done = hasDuration && remaining <= 0
    val shape = RoundedCornerShape(20.dp)
    val secondary = MaterialTheme.colorScheme.onSurfaceVariant

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(
                Brush.linearGradient(
                    listOf(
                        MaterialTheme.colorScheme.primary.copy(alpha = 0.18f),
                        MaterialTheme.colorScheme.primary.copy(alpha = 0.04f)
                    )
                )
            )
            .border(
                1.dp,
                MaterialTheme.colorScheme.primary.copy(alpha = 0.22f),
                shape
            )
            .padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Finishes at", fontWeight = FontWeight.SemiBold)
            Spacer(Modifier.weight(1f))
            if (done) {
                Text(
                    text = "Done",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color(0xFF7BD88F)
                )
            }
        }

        Text(
            text = if (hasDuration) PrintTime.clockLabel(finishMillis) else "--:--",
            fontSize = 46.sp,
            fontWeight = FontWeight.Bold,
            fontFamily = FontFamily.Monospace,
            color = MaterialTheme.colorScheme.onSurface.copy(
                alpha = if (hasDuration) 1f else 0.3f
            )
        )

        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            if (hasDuration) {
                Text(
                    text = PrintTime.dayLabel(finishMillis, nowMillis),
                    fontSize = 13.sp,
                    color = secondary
                )
                Text("·", fontSize = 13.sp, color = secondary.copy(alpha = 0.5f))
                Text(
                    text = "${PrintTime.durationLabel(viewModel.hours, viewModel.minutes)} print",
                    fontSize = 13.sp,
                    color = secondary
                )
            } else {
                Text(
                    text = "Enter your print time above to get started.",
                    fontSize = 13.sp,
                    color = secondary
                )
            }
        }

        if (hasDuration) {
            LinearProgressIndicator(
                progress = { progress },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(6.dp)
                    .clip(RoundedCornerShape(3.dp)),
                color = MaterialTheme.colorScheme.primary,
                trackColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.12f)
            )
            Row {
                Text(
                    text = if (done) "Finished" else PrintTime.countdownLabel(remaining),
                    fontSize = 12.sp,
                    color = secondary
                )
                Spacer(Modifier.weight(1f))
                Text(
                    text = "${(progress * 100).toInt()}%",
                    fontSize = 12.sp,
                    color = secondary
                )
            }
        }
    }
}

@Composable
private fun SectionCard(content: @Composable ColumnScope.() -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(MaterialTheme.colorScheme.surface)
            .border(
                1.dp,
                MaterialTheme.colorScheme.outline.copy(alpha = 0.25f),
                RoundedCornerShape(18.dp)
            )
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
        content = content
    )
}
