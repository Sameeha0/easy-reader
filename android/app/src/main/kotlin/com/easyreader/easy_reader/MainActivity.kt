package com.easyreader.easy_reader

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// Receives files from "Open with" / "Share" and passes them to Flutter.
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "easy_reader/open")
        channel!!.setMethodCallHandler { call, result ->
            if (call.method == "initialFile") result.success(copyIncoming(intent)) else result.notImplemented()
        }
    }

    // app was already open
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        copyIncoming(intent)?.let { channel?.invokeMethod("newFile", it) }
    }

    // copies the file into the cache so Flutter can read it, returns [path, name]
    private fun copyIncoming(intent: Intent?): List<String>? {
        val uri: Uri = when (intent?.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> @Suppress("DEPRECATION") intent.getParcelableExtra(Intent.EXTRA_STREAM)
            else -> null
        } ?: return null
        intent?.action = null // don't open it again when the screen rotates

        var name = "document"
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
            if (it.moveToFirst()) name = it.getString(0) ?: name
        }
        if (!name.contains('.')) {
            val ext = MimeTypeMap.getSingleton().getExtensionFromMimeType(contentResolver.getType(uri))
            name = "$name.$ext"
        }
        val file = File(cacheDir, name)
        contentResolver.openInputStream(uri)?.use { input -> file.outputStream().use { input.copyTo(it) } }
            ?: return null
        return listOf(file.path, name)
    }
}
