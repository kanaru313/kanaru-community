package io.github.kanaru313.kanaru_community

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** MediaStore access for the library module. Methods are added as the library needs them. */
object MediaStoreChannel {
    private const val CHANNEL = "kanaru/media_store"

    fun register(engine: FlutterEngine, context: Context) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { _, result ->
            result.notImplemented()
        }
    }
}
