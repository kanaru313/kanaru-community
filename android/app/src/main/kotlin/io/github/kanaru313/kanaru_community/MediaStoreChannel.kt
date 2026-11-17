package io.github.kanaru313.kanaru_community

import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

/**
 * MediaStore access for the library module (channel `kanaru/media_store`).
 *
 * Queries run on a small background pool and reply on the main looper. Rows
 * cross the channel as parallel lists, not maps. The LIKE pattern is built and
 * escaped in Dart; this side only binds it and re-checks the path prefix.
 */
object MediaStoreChannel {
    private const val CHANNEL = "kanaru/media_store"
    private const val SCAN_WATCHDOG_MS = 3 * 60 * 1000L

    // A few threads, so one query stuck in MediaProvider does not hold up the next calls.
    private val executor = Executors.newFixedThreadPool(3) { r ->
        Thread(r, "kanaru-media-store").apply { isDaemon = true }
    }
    private val main = Handler(Looper.getMainLooper())

    // Callers waiting for the scan in flight. Touched on the main looper only.
    private var scanWaiters: MutableList<MethodChannel.Result>? = null

    fun register(engine: FlutterEngine, context: Context) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sdkInt") {
                result.success(Build.VERSION.SDK_INT)
                return@setMethodCallHandler
            }
            if (call.method == "primaryRoot") {
                // Shared storage of the current user (/storage/emulated/<N>).
                @Suppress("DEPRECATION")
                result.success(Environment.getExternalStorageDirectory().absolutePath)
                return@setMethodCallHandler
            }
            if (call.method == "scanFolders") {
                scanFolders(context, call, result)
                return@setMethodCallHandler
            }
            executor.execute {
                try {
                    val reply: Any? = when (call.method) {
                        "listAudio" -> listAudio(context, call)
                        "listLyrics" -> listLyrics(context, call)
                        "audioFolders" -> audioFolders(context, call)
                        else -> {
                            main.post { result.notImplemented() }
                            return@execute
                        }
                    }
                    main.post { result.success(reply) }
                } catch (e: SecurityException) {
                    main.post { result.error("permission", e.message, null) }
                } catch (e: Throwable) {
                    // Always answer: an unanswered call would hang the Dart future.
                    main.post { result.error("io", e.message, null) }
                }
            }
        }
    }

    /**
     * Asks MediaProvider to scan the given directories and replies once every
     * path has been answered, with {requested, nullUris}.
     *
     * MediaScannerConnection.scanFile calls back once per path, also when a
     * path fails, and MediaProvider walks a directory recursively from API 29.
     * The scan holds the framework-wide background thread for its whole
     * duration, so only one runs at a time: a call made while one is running
     * waits for it and gets its reply (its own paths are not scanned again; the
     * next call covers them). Runs on the main looper, which owns scanWaiters.
     */
    private fun scanFolders(context: Context, call: MethodCall, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error("io", "scanFolders needs API 29", null)
            return
        }
        val paths = call.argument<List<String>>("paths")
        if (paths == null) {
            result.error("io", "paths missing", null)
            return
        }
        val running = scanWaiters
        if (running != null) {
            running.add(result)
            return
        }
        if (paths.isEmpty()) {
            result.success(mapOf("requested" to 0, "nullUris" to 0))
            return
        }
        val waiters = mutableListOf(result)
        scanWaiters = waiters
        val left = AtomicInteger(paths.size)
        val nulls = AtomicInteger(0)
        val finished = AtomicBoolean(false)
        // Callbacks arrive on a framework thread; answer on the main looper, once.
        // A callback that never comes (a wedged MediaProvider) would keep every
        // later call attached to this scan for ever. The watchdog outlasts the
        // Dart-side limit (2 min), so Dart has already given up when it fires;
        // it frees the single-flight slot and answers the waiters. A late
        // callback is then ignored by `finished`.
        lateinit var watchdog: Runnable // assigned below: it and finish() refer to each other
        fun finish(reply: Map<String, Int>?, error: String?) {
            if (!finished.compareAndSet(false, true)) return
            main.post {
                main.removeCallbacks(watchdog)
                scanWaiters = null
                for (waiter in waiters) {
                    if (reply != null) waiter.success(reply) else waiter.error("io", error, null)
                }
            }
        }
        watchdog = Runnable { finish(null, "scan timed out") }
        main.postDelayed(watchdog, SCAN_WATCHDOG_MS)
        try {
            MediaScannerConnection.scanFile(context, paths.toTypedArray(), null) { _, uri ->
                if (uri == null) nulls.incrementAndGet()
                if (left.decrementAndGet() == 0) {
                    finish(mapOf("requested" to paths.size, "nullUris" to nulls.get()), null)
                }
            }
        } catch (e: Throwable) {
            finish(null, e.message ?: "scanFile failed")
        }
    }

    private fun audioUri(): Uri =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }

    private fun filesUri(): Uri =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Files.getContentUri("external")
        }

    private fun isUnder(path: String, root: String): Boolean =
        path.startsWith("$root/", ignoreCase = true)

    private fun listAudio(context: Context, call: MethodCall): Map<String, Any> {
        val pattern = call.argument<String>("likePattern") ?: throw IllegalArgumentException("likePattern")
        val root = call.argument<String>("root") ?: throw IllegalArgumentException("root")
        val paths = ArrayList<String>()
        val sizes = ArrayList<Long>()
        val modified = ArrayList<Long>()
        val durations = ArrayList<Long>()
        var emptyPaths = 0
        val projection = arrayOf(
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATE_MODIFIED,
            MediaStore.Audio.Media.DURATION,
        )
        context.contentResolver.query(
            audioUri(), projection, "${MediaStore.Audio.Media.DATA} LIKE ? ESCAPE '\\'", arrayOf(pattern), null,
        )?.use { c ->
            val iData = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val iSize = c.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
            val iMod = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)
            val iDur = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            while (c.moveToNext()) {
                val path = c.getString(iData)
                if (path.isNullOrEmpty()) {
                    emptyPaths++
                    continue
                }
                if (!isUnder(path, root)) continue
                paths.add(path)
                sizes.add(c.getLong(iSize))
                modified.add(c.getLong(iMod))
                durations.add(if (c.isNull(iDur)) -1L else c.getLong(iDur))
            }
        } ?: throw IllegalStateException("MediaStore query returned null")
        return mapOf(
            "paths" to paths,
            "sizes" to sizes.toLongArray(),
            "modifiedSec" to modified.toLongArray(),
            "durationsMs" to durations.toLongArray(),
            "emptyPaths" to emptyPaths,
        )
    }

    private fun listLyrics(context: Context, call: MethodCall): Map<String, Any> {
        val pattern = call.argument<String>("likePattern") ?: throw IllegalArgumentException("likePattern")
        val root = call.argument<String>("root") ?: throw IllegalArgumentException("root")
        val paths = ArrayList<String>()
        val sizes = ArrayList<Long>()
        val modified = ArrayList<Long>()
        val projection = arrayOf(
            MediaStore.Files.FileColumns.DATA,
            MediaStore.Files.FileColumns.SIZE,
            MediaStore.Files.FileColumns.DATE_MODIFIED,
        )
        context.contentResolver.query(
            filesUri(), projection, "${MediaStore.Files.FileColumns.DATA} LIKE ? ESCAPE '\\'",
            arrayOf(pattern), null,
        )?.use { c ->
            val iData = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATA)
            val iSize = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)
            val iMod = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_MODIFIED)
            while (c.moveToNext()) {
                val path = c.getString(iData)
                if (path.isNullOrEmpty() || !isUnder(path, root)) continue
                paths.add(path)
                sizes.add(c.getLong(iSize))
                modified.add(c.getLong(iMod))
            }
        } ?: throw IllegalStateException("MediaStore query returned null")
        return mapOf("paths" to paths, "sizes" to sizes.toLongArray(), "modifiedSec" to modified.toLongArray())
    }

    /** Parent folders of audio rows with their row counts; rows shorter than minDurationMs are not counted. */
    private fun audioFolders(context: Context, call: MethodCall): Map<String, Any> {
        val minDurationMs = (call.argument<Number>("minDurationMs") ?: 0).toLong()
        val extensions = (call.argument<List<String>>("extensions") ?: emptyList()).toSet()
        val counts = LinkedHashMap<String, Int>()
        val projection = arrayOf(MediaStore.Audio.Media.DATA, MediaStore.Audio.Media.DURATION)
        context.contentResolver.query(audioUri(), projection, null, null, null)?.use { c ->
            val iData = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val iDur = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            while (c.moveToNext()) {
                val path = c.getString(iData)
                if (path.isNullOrEmpty()) continue
                val slash = path.lastIndexOf('/')
                if (slash <= 0) continue
                // Same allow list as listAudio, so the first-run estimate matches the scan.
                if (extensions.isNotEmpty() &&
                    path.substringAfterLast('.', "").lowercase() !in extensions
                ) continue
                val duration = if (c.isNull(iDur)) -1L else c.getLong(iDur)
                if (minDurationMs > 0 && duration in 1 until minDurationMs) continue
                val folder = path.substring(0, slash)
                counts[folder] = (counts[folder] ?: 0) + 1
            }
        } ?: throw IllegalStateException("MediaStore query returned null")
        return mapOf("paths" to counts.keys.toList(), "counts" to counts.values.toIntArray())
    }
}
