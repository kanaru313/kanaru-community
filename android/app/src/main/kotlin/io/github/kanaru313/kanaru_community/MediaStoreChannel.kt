package io.github.kanaru313.kanaru_community

import android.content.Context
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

/**
 * MediaStore access for the library module (channel `kanaru/media_store`).
 *
 * Queries run on a small background pool and reply on the main looper. Rows
 * cross the channel as parallel lists, not maps. The LIKE pattern is built and
 * escaped in Dart; this side only binds it and re-checks the path prefix.
 */
object MediaStoreChannel {
    private const val CHANNEL = "kanaru/media_store"

    // A few threads, so one query stuck in MediaProvider does not hold up the next calls.
    private val executor = Executors.newFixedThreadPool(3) { r ->
        Thread(r, "kanaru-media-store").apply { isDaemon = true }
    }
    private val main = Handler(Looper.getMainLooper())

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
