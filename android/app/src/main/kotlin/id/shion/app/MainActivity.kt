package id.shion.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.objects.ObjectDetection
import com.google.mlkit.vision.objects.ObjectDetector
import com.google.mlkit.vision.objects.defaults.ObjectDetectorOptions

class MainActivity : FlutterActivity() {
    private var detector: ObjectDetector? = null
    private var busy = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "id.shion.app/object_detection")
            .setMethodCallHandler { call, result ->
                if (call.method != "detect") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (busy) {
                    result.success(null)
                    return@setMethodCallHandler
                }
                try {
                    val bytes = requireNotNull(call.argument<ByteArray>("bytes"))
                    val width = requireNotNull(call.argument<Int>("width"))
                    val height = requireNotNull(call.argument<Int>("height"))
                    val rotation = requireNotNull(call.argument<Int>("rotation"))
                    if (detector == null) {
                        detector = ObjectDetection.getClient(ObjectDetectorOptions.Builder()
                            .setDetectorMode(ObjectDetectorOptions.STREAM_MODE)
                            .enableMultipleObjects().build())
                    }
                    val image = InputImage.fromByteArray(bytes, width, height, rotation, InputImage.IMAGE_FORMAT_NV21)
                    busy = true
                    detector!!.process(image)
                        .addOnSuccessListener { objects ->
                            val rotated = rotation == 90 || rotation == 270
                            result.success(mapOf(
                                "width" to if (rotated) height else width,
                                "height" to if (rotated) width else height,
                                "boxes" to objects.map { val b = it.boundingBox; listOf(b.left, b.top, b.right, b.bottom) }
                            ))
                        }
                        .addOnFailureListener { error -> result.error("DETECTION_FAILED", error.message, null) }
                        .addOnCompleteListener { busy = false }
                } catch (error: Exception) {
                    busy = false
                    result.error("INVALID_FRAME", error.message, null)
                }
            }
    }

    override fun onDestroy() {
        detector?.close()
        detector = null
        super.onDestroy()
    }
}
