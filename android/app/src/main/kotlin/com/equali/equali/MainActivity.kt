package com.equali.equali

import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.Virtualizer
import android.net.ConnectivityManager
import android.content.Context
import java.net.Inet4Address
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

@Suppress("DEPRECATION")
class MainActivity : FlutterActivity() {
    private var equalizer: Equalizer? = null
    private var bass: BassBoost? = null
    private var virtualizer: Virtualizer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "equali/network")
            .setMethodCallHandler { call, result ->
                if (call.method != "getAddress") { result.notImplemented() }
                else {
                    val connectivity = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                    val address = connectivity.getLinkProperties(connectivity.activeNetwork)
                        ?.linkAddresses?.map { it.address }
                        ?.firstOrNull { it is Inet4Address && !it.isLoopbackAddress }?.hostAddress
                    result.success(address)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "equali/audio_effects")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "attach" -> {
                            releaseEffects()
                            val session = call.argument<Int>("session") ?: 0
                            if (session != 0) {
                                equalizer = runCatching { Equalizer(0, session) }.getOrNull()
                                bass = runCatching { BassBoost(0, session) }.getOrNull()
                                virtualizer = runCatching { Virtualizer(0, session) }.getOrNull()
                            }
                            result.success(mapOf("equalizer" to (equalizer != null),
                                "bass" to (bass?.strengthSupported == true),
                                "virtualizer" to (virtualizer?.strengthSupported == true)))
                        }
                        "update" -> {
                            val enabled = call.argument<Boolean>("enabled") ?: true
                            equalizer?.let { eq ->
                                eq.enabled = enabled
                                val gains = call.argument<List<Number>>("gains") ?: emptyList()
                                val frequencies = listOf(60, 230, 910, 3600, 14000)
                                val range = eq.bandLevelRange
                                gains.take(5).forEachIndexed { index, gain ->
                                    val band = eq.getBand(frequencies[index] * 1000)
                                    eq.setBandLevel(band, (gain.toDouble() * 100).toInt()
                                        .coerceIn(range[0].toInt(), range[1].toInt()).toShort())
                                }
                            }
                            bass?.let { effect ->
                                val strength = call.argument<Number>("bass")?.toDouble() ?: 0.0
                                effect.enabled = strength > 0
                                if (effect.strengthSupported) effect.setStrength((strength * 1000).toInt().coerceIn(0, 1000).toShort())
                            }
                            virtualizer?.let { effect ->
                                val spatial = call.argument<Boolean>("spatial") ?: false
                                val strength = call.argument<Number>(if (spatial) "surround" else "virtualizer")?.toDouble() ?: 0.0
                                effect.enabled = strength > 0
                                if (effect.strengthSupported) effect.setStrength((strength * 1000).toInt().coerceIn(0, 1000).toShort())
                            }
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("AUDIO_EFFECT", error.message, null)
                }
            }
    }

    private fun releaseEffects() {
        equalizer?.release(); equalizer = null
        bass?.release(); bass = null
        virtualizer?.release(); virtualizer = null
    }
    override fun onDestroy() { releaseEffects(); super.onDestroy() }
}
