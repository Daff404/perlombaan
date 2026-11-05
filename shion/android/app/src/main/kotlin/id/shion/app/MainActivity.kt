package id.shion.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.speech.tts.TextToSpeech
import java.util.Locale
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.os.Build
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class MainActivity : FlutterActivity() {
    private var textToSpeech: TextToSpeech? = null
    private var speechReady = false
    private var pendingSpeech: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) notificationManager.createNotificationChannel(NotificationChannel("shion_updates", "Kabar SHION", NotificationManager.IMPORTANCE_HIGH))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "id.shion.app/notifications").setMethodCallHandler { call, result ->
            when (call.method) {
                "channel" -> result.success(null)
                "show" -> {
                    if (Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                        result.success(null)
                    } else {
                        val launch = packageManager.getLaunchIntentForPackage(packageName)
                        val pending = PendingIntent.getActivity(this, 0, launch, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
                        val notification = NotificationCompat.Builder(this, "shion_updates")
                            .setSmallIcon(resources.getIdentifier("ic_shion", "drawable", packageName))
                            .setContentTitle(call.argument<String>("title") ?: "SHION")
                            .setContentText(call.argument<String>("body") ?: "")
                            .setStyle(NotificationCompat.BigTextStyle().bigText(call.argument<String>("body") ?: ""))
                            .setPriority(NotificationCompat.PRIORITY_HIGH).setAutoCancel(true).setContentIntent(pending).build()
                        notificationManager.notify((call.argument<String>("id") ?: "shion").hashCode(), notification)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "id.shion.app/speech")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "speak" -> {
                        val text = call.argument<String>("text")?.trim().orEmpty()
                        if (text.isEmpty()) {
                            result.error("EMPTY_TEXT", "Tidak ada teks untuk dibacakan.", null)
                            return@setMethodCallHandler
                        }
                        speakIndonesian(text)
                        result.success(null)
                    }
                    "stop" -> {
                        pendingSpeech = null
                        textToSpeech?.stop()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun speakIndonesian(text: String) {
        if (textToSpeech == null) {
            pendingSpeech = text
            textToSpeech = TextToSpeech(applicationContext) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    speechReady = true
                    val engine = textToSpeech ?: return@TextToSpeech
                    val idLocale = Locale("id", "ID")
                    val languageResult = engine.setLanguage(idLocale)
                    if (languageResult == TextToSpeech.LANG_MISSING_DATA ||
                        languageResult == TextToSpeech.LANG_NOT_SUPPORTED) {
                        engine.setLanguage(Locale("id"))
                    }
                    engine.setSpeechRate(0.95f)
                    pendingSpeech?.also {
                        pendingSpeech = null
                        engine.speak(it, TextToSpeech.QUEUE_FLUSH, null, "shion-scan-result")
                    }
                }
            }
            return
        }
        if (!speechReady) {
            pendingSpeech = text
            return
        }
        textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "shion-scan-result")
    }

    override fun onDestroy() {
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
        super.onDestroy()
    }
}
