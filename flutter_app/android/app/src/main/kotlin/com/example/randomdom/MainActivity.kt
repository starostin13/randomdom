package com.example.randomdom

import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	companion object {
		private const val CHANNEL = "randomdom/android_apps"
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"getInstalledApps" -> result.success(getInstalledApps())
					"launchApp" -> {
						val packageName = call.argument<String>("packageName")?.trim().orEmpty()
						if (packageName.isEmpty()) {
							result.success(false)
							return@setMethodCallHandler
						}
						result.success(launchApp(packageName))
					}
					else -> result.notImplemented()
				}
			}
	}

	private fun getInstalledApps(): List<Map<String, String>> {
		val packageManager = applicationContext.packageManager
		val applications = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
		val result = mutableListOf<Map<String, String>>()

		for (application in applications) {
			val packageName = application.packageName ?: continue
			if (packageName == applicationContext.packageName) {
				continue
			}

			val launchIntent = packageManager.getLaunchIntentForPackage(packageName) ?: continue
			if (launchIntent.action == null) {
				// Skip entries without a valid launch intent.
				continue
			}

			val label = packageManager.getApplicationLabel(application).toString().trim()
			val appName = if (label.isNotEmpty()) label else packageName
			result.add(
				mapOf(
					"appName" to appName,
					"packageName" to packageName,
				),
			)
		}

		return result.sortedBy { it["appName"]?.lowercase() ?: "" }
	}

	private fun launchApp(packageName: String): Boolean {
		val packageManager = applicationContext.packageManager
		val launchIntent = packageManager.getLaunchIntentForPackage(packageName) ?: return false
		launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

		return try {
			applicationContext.startActivity(launchIntent)
			true
		} catch (_: Exception) {
			false
		}
	}
}
