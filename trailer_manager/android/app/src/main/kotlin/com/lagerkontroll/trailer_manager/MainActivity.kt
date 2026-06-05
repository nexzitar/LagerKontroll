package com.lagerkontroll.trailer_manager

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val SMS_CHANNEL = "com.lagerkontroll.trailer_manager/sms"
    private val INSTALL_CHANNEL = "com.lagerkontroll.trailer_manager/install"
    private val SMS_PERMISSION_CODE = 101
    private var pendingResult: MethodChannel.Result? = null
    private var pendingPhoneNumber: String? = null
    private var pendingMessage: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // SMS Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendSms" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val message = call.argument<String>("message")

                    if (phoneNumber == null || message == null) {
                        result.error("INVALID_ARGUMENTS", "Phone number and message are required", null)
                        return@setMethodCallHandler
                    }

                    // Check if we have SMS permission
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
                        != PackageManager.PERMISSION_GRANTED) {
                        // Request permission
                        pendingResult = result
                        pendingPhoneNumber = phoneNumber
                        pendingMessage = message
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.SEND_SMS),
                            SMS_PERMISSION_CODE
                        )
                    } else {
                        // Permission already granted, send SMS
                        sendSmsMessage(phoneNumber, message, result)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Install APK Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath == null) {
                        result.error("INVALID_ARGUMENTS", "File path is required", null)
                        return@setMethodCallHandler
                    }
                    installApk(filePath, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun installApk(filePath: String, result: MethodChannel.Result) {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "APK file not found: $filePath", null)
                return
            }

            val intent = Intent(Intent.ACTION_VIEW)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // For Android 7.0 and above, use FileProvider
                val uri = FileProvider.getUriForFile(
                    this,
                    "${applicationContext.packageName}.fileprovider",
                    file
                )
                intent.setDataAndType(uri, "application/vnd.android.package-archive")
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } else {
                // For older versions, use file:// URI
                intent.setDataAndType(Uri.fromFile(file), "application/vnd.android.package-archive")
            }

            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("INSTALL_ERROR", "Failed to install APK: ${e.message}", null)
        }
    }

    private fun sendSmsMessage(phoneNumber: String, message: String, result: MethodChannel.Result) {
        try {
            val smsManager = SmsManager.getDefault()

            // For messages longer than 160 characters, split into multiple parts
            val parts = smsManager.divideMessage(message)

            if (parts.size == 1) {
                smsManager.sendTextMessage(phoneNumber, null, message, null, null)
            } else {
                smsManager.sendMultipartTextMessage(phoneNumber, null, parts, null, null)
            }

            result.success(true)
        } catch (e: Exception) {
            result.error("SMS_ERROR", "Failed to send SMS: ${e.message}", null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == SMS_PERMISSION_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Permission granted, send the pending SMS
                if (pendingPhoneNumber != null && pendingMessage != null && pendingResult != null) {
                    sendSmsMessage(pendingPhoneNumber!!, pendingMessage!!, pendingResult!!)
                }
            } else {
                // Permission denied
                pendingResult?.error("PERMISSION_DENIED", "SMS permission was denied", null)
            }

            // Clear pending data
            pendingResult = null
            pendingPhoneNumber = null
            pendingMessage = null
        }
    }
}
