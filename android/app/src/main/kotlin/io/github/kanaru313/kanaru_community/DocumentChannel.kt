package io.github.kanaru313.kanaru_community

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.FileNotFoundException
import java.lang.ref.WeakReference
import java.util.concurrent.Executors

/**
 * Single-document access through the Storage Access Framework (channel
 * `kanaru/documents`): open and create dialogs, bounded read, write, discard.
 *
 * This is a process-level object: the engine is cached and outlives any one
 * activity, so the pending dialog request lives here, not in an activity. The
 * activity is held weakly and replaced on every attach.
 */
object DocumentChannel {
    private const val CHANNEL = "kanaru/documents"
    // Each dialog gets its own request code from this range, so the result of
    // an old picker can never answer a newer request.
    private const val REQUEST_BASE = 0x7000
    private const val REQUEST_RANGE = 0x0800
    private const val DEFAULT_MIME = "application/octet-stream"
    private const val ORPHAN_CHECK_MS = 2000L

    private val executor = Executors.newFixedThreadPool(2) { r ->
        Thread(r, "kanaru-documents").apply { isDaemon = true }
    }
    private val main = Handler(Looper.getMainLooper())

    // The dialog in flight. Touched on the main looper only.
    private var pending: Pending? = null
    private var activity: WeakReference<Activity>? = null
    private var requestCounter = 0

    // Application context kept from attach: it outlives every activity, so a
    // pick is still delivered when another instance's detach cleared `activity`.
    private var appContext: Context? = null

    // [owner] is the activity that launched the dialog.
    private class Pending(
        val requestCode: Int,
        val result: MethodChannel.Result,
        val owner: WeakReference<Activity>,
    )

    /** The request's activity was destroyed: only a re-created one can deliver its result. */
    private fun Pending.ownerGone(): Boolean = owner.get()?.isDestroyed ?: true

    /**
     * Called from every `configureFlutterEngine`; keeps only a weak activity.
     * [restored] is true when the activity was re-created from saved state.
     */
    fun attach(engine: FlutterEngine, activity: Activity, restored: Boolean) {
        this.activity = WeakReference(activity)
        appContext = activity.applicationContext
        // A dialog whose owner was destroyed may still deliver its result to
        // this restored activity, in the same main-looper message as its
        // creation. Give it a moment, then answer null so Dart never waits
        // forever. A second live instance on top of the picker is not an
        // orphan: its owner is alive and keeps its request.
        val orphan = pending
        if (orphan != null && restored && orphan.ownerGone()) {
            main.postDelayed({
                if (pending === orphan) answerPending(null)
            }, ORPHAN_CHECK_MS)
        }
        val context = activity.applicationContext
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            handle(context, call, result)
        }
    }

    /** Called from `MainActivity.onDestroy` of [activity]. */
    fun detach(activity: Activity) {
        if (this.activity?.get() === activity) {
            this.activity = null
        }
        val open = pending ?: return
        // Destroyed for good (task swiped away): nobody can deliver the result.
        // Otherwise the request is kept for the re-created activity (see attach).
        if (open.owner.get() === activity && activity.isFinishing) answerPending(null)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        val current = pending ?: return false
        if (current.requestCode != requestCode) return false
        pending = null
        val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
        val context = appContext
        if (uri == null || context == null) {
            current.result.success(null)
            return true
        }
        // Resolving the display name can touch the provider: off the main thread.
        executor.execute {
            try {
                val reply = describe(context, uri)
                main.post { current.result.success(reply) }
            } catch (e: Throwable) {
                main.post { current.result.error("io", e.message, null) }
            }
        }
        return true
    }

    private fun answerPending(value: Any?) {
        val current = pending ?: return
        pending = null
        current.result.success(value)
    }

    private fun handle(context: Context, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "open" -> {
                @Suppress("UNCHECKED_CAST")
                val mimes = (call.argument<List<String>>("mimeTypes") ?: emptyList()).distinct()
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "*/*"
                    if (mimes.isNotEmpty()) putExtra(Intent.EXTRA_MIME_TYPES, mimes.toTypedArray())
                }
                launch(intent, result)
            }
            "create" -> {
                val name = call.argument<String>("name") ?: "playlist.m3u8"
                val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = mimeFor(name)
                    putExtra(Intent.EXTRA_TITLE, name)
                }
                launch(intent, result)
            }
            "read", "write", "discard" -> io(context, call, result)
            else -> result.notImplemented()
        }
    }

    /**
     * MIME type from the extension of [name]. A MIME whose default extension
     * differs from the name's makes the provider append its own
     * (`Mix.m3u8.m3u`), so the extension decides.
     */
    private fun mimeFor(name: String): String {
        val ext = name.substringAfterLast('.', "").lowercase()
        if (ext.isEmpty()) return DEFAULT_MIME
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext) ?: DEFAULT_MIME
    }

    private fun launch(intent: Intent, result: MethodChannel.Result) {
        val host = activity?.get()
        val open = pending
        if (open != null) {
            // A request whose owner is alive keeps the dialog; one whose owner
            // was destroyed is an orphan: it ends as cancelled and this one
            // proceeds.
            if (!open.ownerGone()) {
                result.error("busy", "another document dialog is open", null)
                return
            }
            answerPending(null)
        }
        if (host == null || host.isFinishing || host.isDestroyed) {
            result.success(null)
            return
        }
        val requestCode = REQUEST_BASE + (requestCounter++ % REQUEST_RANGE)
        val request = Pending(requestCode, result, WeakReference(host))
        pending = request
        try {
            host.startActivityForResult(intent, requestCode)
        } catch (e: Exception) {
            // Whatever the launch threw, the request is over and answered once.
            if (pending === request) pending = null
            result.error(if (e is ActivityNotFoundException) "unavailable" else "io", e.message, null)
        }
    }

    /** {uri, name, displayName, authority, documentId} of a picked document. */
    private fun describe(context: Context, uri: Uri): Map<String, Any?> {
        var name: String? = null
        context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
            if (it.moveToFirst()) name = it.getString(0)
        }
        val documentId = try {
            if (DocumentsContract.isDocumentUri(context, uri)) DocumentsContract.getDocumentId(uri) else null
        } catch (e: IllegalArgumentException) {
            null
        }
        return mapOf(
            "uri" to uri.toString(),
            "name" to name,
            "displayName" to name,
            "authority" to uri.authority,
            "documentId" to documentId,
        )
    }

    private fun io(context: Context, call: MethodCall, result: MethodChannel.Result) {
        val uri = call.argument<String>("uri")?.let { Uri.parse(it) }
        if (uri == null) {
            result.error("args", "missing uri", null)
            return
        }
        executor.execute {
            try {
                val reply: Any? = when (call.method) {
                    "read" -> readBounded(context, uri, (call.argument<Number>("max") ?: 0).toLong())
                    "write" -> {
                        val bytes = call.argument<ByteArray>("bytes") ?: ByteArray(0)
                        // "wt" truncates: a shorter text must not keep an old tail.
                        val stream = try {
                            context.contentResolver.openOutputStream(uri, "wt")
                        } catch (e: Exception) {
                            // Some providers refuse "wt"; the document was just
                            // created and is empty, so plain "w" is equivalent.
                            if (e is IllegalArgumentException || e is FileNotFoundException ||
                                e is UnsupportedOperationException
                            ) {
                                context.contentResolver.openOutputStream(uri, "w")
                            } else {
                                throw e
                            }
                        } ?: throw FileNotFoundException("no output stream")
                        stream.use { it.write(bytes) }
                        null
                    }
                    else -> {
                        DocumentsContract.deleteDocument(context.contentResolver, uri)
                        null
                    }
                }
                main.post { result.success(reply) }
            } catch (e: TooLarge) {
                main.post { result.error("too_large", e.message, null) }
            } catch (e: FileNotFoundException) {
                main.post { result.error("not_found", e.message, null) }
            } catch (e: SecurityException) {
                main.post { result.error("permission", e.message, null) }
            } catch (e: Throwable) {
                // Always answer: an unanswered call would hang the Dart future.
                main.post { result.error("io", e.message, null) }
            }
        }
    }

    private class TooLarge : Exception("document is larger than the limit")

    /** At most [max] bytes; one byte more is [TooLarge], so nothing bigger crosses the channel. */
    private fun readBounded(context: Context, uri: Uri, max: Long): ByteArray {
        val stream = context.contentResolver.openInputStream(uri)
            ?: throw FileNotFoundException("no input stream")
        stream.use { input ->
            val out = ByteArrayOutputStream()
            val buffer = ByteArray(64 * 1024)
            var total = 0L
            while (true) {
                val n = input.read(buffer)
                if (n < 0) break
                total += n
                if (total > max) throw TooLarge()
                out.write(buffer, 0, n)
            }
            return out.toByteArray()
        }
    }
}
