package io.github.kanaru313.kanaru_community

import android.content.Intent
import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : AudioServiceActivity() {
    // Set before super.onCreate, which calls configureFlutterEngine.
    private var restored = false

    override fun onCreate(savedInstanceState: Bundle?) {
        restored = savedInstanceState != null
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MediaStoreChannel.register(flutterEngine, applicationContext)
        DocumentChannel.attach(flutterEngine, this, restored)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        DocumentChannel.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        DocumentChannel.detach(this)
        super.onDestroy()
    }
}
