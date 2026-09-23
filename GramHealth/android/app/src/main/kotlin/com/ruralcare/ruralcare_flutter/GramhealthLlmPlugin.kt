package com.gramhealth

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.StatFs
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.io.File

/**
 * Native Android plugin for LiteRT-LM on-device inference.
 *
 * Method channel:  gramhealth/offline_llm
 * Event channel:   gramhealth/offline_llm_tokens
 *
 * ─── LiteRT-LM Integration Note ────────────────────────────────────────────
 * This plugin targets the MediaPipe / Google AI Edge LLM Inference Task API.
 *
 * Dependency to add in android/app/build.gradle:
 *   implementation 'com.google.mediapipe:tasks-genai:0.10.14'
 *
 * The exact class path is:
 *   com.google.mediapipe.tasks.genai.llminference.LlmInference
 *
 * IMPORTANT: Verify the latest stable version of tasks-genai on
 * https://mvnrepository.com/artifact/com.google.mediapipe/tasks-genai
 * before shipping. Do NOT hardcode a version without checking.
 *
 * ABI support: arm64-v8a (required), armeabi-v7a (optional / slower)
 * Min SDK: 26 (Android 8.0)
 * RAM: ~1.5 GB minimum recommended for 0.5B q8 model
 * ─────────────────────────────────────────────────────────────────────────────
 */
class GramhealthLlmPlugin : FlutterPlugin, MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var context: Context

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var generationJob: Job? = null

    // LlmInference instance — loaded lazily
    // Type is Any? so this file compiles even if the dependency is not yet
    // on the classpath. At runtime, the class must be present.
    private var llmInference: Any? = null

    // ─── FlutterPlugin ────────────────────────────────────────────────────────

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "gramhealth/offline_llm")
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "gramhealth/offline_llm_tokens")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        disposeLlm()
        scope.cancel()
    }

    // ─── MethodCallHandler ────────────────────────────────────────────────────

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "generate"   -> handleGenerate(call, result)
            "cancel"     -> handleCancel(result)
            "dispose"    -> { disposeLlm(); result.success(null) }
            "checkCompatibility" -> handleCompatibility(result)
            else -> result.notImplemented()
        }
    }

    // ─── initialize ───────────────────────────────────────────────────────────

    private fun handleInitialize(call: MethodCall, result: Result) {
        val modelPath = call.argument<String>("modelPath")
            ?: return result.error("INVALID_ARGS", "modelPath required", null)
        val maxTokens  = call.argument<Int>("maxTokens")   ?: 400
        val temperature = call.argument<Double>("temperature") ?: 0.2
        val topK        = call.argument<Int>("topK")       ?: 40

        scope.launch {
            try {
                // ── MediaPipe LlmInference initialization ──
                //
                // Replace the reflection-based call below with direct class
                // usage once you have confirmed the dependency is on the
                // classpath:
                //
                //   import com.google.mediapipe.tasks.genai.llminference.LlmInference
                //
                //   val options = LlmInference.LlmInferenceOptions.builder()
                //       .setModelPath(modelPath)
                //       .setMaxTokens(maxTokens)
                //       .setTemperature(temperature.toFloat())
                //       .setTopK(topK)
                //       .build()
                //   llmInference = LlmInference.createFromOptions(context, options)
                //
                // The reflection approach below provides a compile-time shim
                // so the Dart layer can be fully tested before the native
                // dependency is confirmed.

                val llmClass = Class.forName(
                    "com.google.mediapipe.tasks.genai.llminference.LlmInference"
                )
                val optionsClass = Class.forName(
                    "com.google.mediapipe.tasks.genai.llminference.LlmInference\$LlmInferenceOptions"
                )
                val builderClass = Class.forName(
                    "com.google.mediapipe.tasks.genai.llminference.LlmInference\$LlmInferenceOptions\$Builder"
                )
                val builderInstance = optionsClass.getMethod("builder")
                    .invoke(null)
                builderClass.getMethod("setModelPath", String::class.java)
                    .invoke(builderInstance, modelPath)
                builderClass.getMethod("setMaxTokens", Int::class.java)
                    .invoke(builderInstance, maxTokens)
                builderClass.getMethod("setTemperature", Float::class.java)
                    .invoke(builderInstance, temperature.toFloat())
                builderClass.getMethod("setTopK", Int::class.java)
                    .invoke(builderInstance, topK)
                val options = builderClass.getMethod("build")
                    .invoke(builderInstance)
                llmInference = llmClass
                    .getMethod("createFromOptions",
                        Context::class.java,
                        optionsClass)
                    .invoke(null, context, options)

                withContext(Dispatchers.Main) { result.success(null) }
            } catch (e: ClassNotFoundException) {
                withContext(Dispatchers.Main) {
                    result.error(
                        "LLM_DEPENDENCY_MISSING",
                        "com.google.mediapipe:tasks-genai is not on the "
                            + "classpath. Add it to android/app/build.gradle.",
                        e.toString()
                    )
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("LLM_INIT_FAILED", e.message, e.toString())
                }
            }
        }
    }

    // ─── generate ─────────────────────────────────────────────────────────────

    private fun handleGenerate(call: MethodCall, result: Result) {
        val llm = llmInference
            ?: return result.error("NOT_INITIALIZED", "Model not loaded", null)

        val systemPrompt = call.argument<String>("systemPrompt") ?: ""
        val userPrompt   = call.argument<String>("prompt")       ?: ""

        // Build ChatML-style prompt for Qwen2.5
        val fullPrompt = buildQwenPrompt(systemPrompt, userPrompt)

        result.success(null) // ack immediately; tokens come via event channel

        generationJob = scope.launch {
            try {
                // Streaming callback listener
                //
                // Uncomment and use the direct API once confirmed:
                //   llm as LlmInference
                //   llm.generateAsync(fullPrompt) { partial, done ->
                //       sink?.success(partial)
                //       if (done) sink?.success("__EOS__")
                //   }
                //
                // Reflection-based shim:
                val listenerClass = Class.forName(
                    "com.google.mediapipe.tasks.genai.llminference"
                        + ".LlmInference\$LlmInferenceResultListener"
                )
                val proxy = java.lang.reflect.Proxy.newProxyInstance(
                    listenerClass.classLoader,
                    arrayOf(listenerClass)
                ) { _, method, args ->
                    if (method.name == "run" && args != null && args.size >= 2) {
                        val partial = args[0] as? String ?: ""
                        val done    = args[1] as? Boolean ?: false
                        CoroutineScope(Dispatchers.Main).launch {
                            eventSink?.success(partial)
                            if (done) eventSink?.success("__EOS__")
                        }
                    }
                    null
                }
                llm.javaClass
                    .getMethod("generateAsync", String::class.java, listenerClass)
                    .invoke(llm, fullPrompt, proxy)
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    eventSink?.error("GENERATION_FAILED", e.message, null)
                }
            }
        }
    }

    private fun buildQwenPrompt(system: String, user: String): String {
        // Qwen2.5 ChatML format
        return "<|im_start|>system\n$system<|im_end|>\n" +
               "<|im_start|>user\n$user<|im_end|>\n" +
               "<|im_start|>assistant\n"
    }

    // ─── cancel ───────────────────────────────────────────────────────────────

    private fun handleCancel(result: Result) {
        generationJob?.cancel()
        generationJob = null
        scope.launch(Dispatchers.Main) {
            eventSink?.success("__EOS__")
        }
        result.success(null)
    }

    // ─── compatibility ────────────────────────────────────────────────────────

    private fun handleCompatibility(result: Result) {
        val apiLevel   = Build.VERSION.SDK_INT
        val supported  = apiLevel >= 26
        val enoughStorage = checkFreeStorage(700_000_000L)
        val enoughMemory  = checkAvailableRam(1_500_000_000L)
        val abi = Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown"

        result.success(mapOf(
            "supported"     to supported,
            "enoughStorage" to enoughStorage,
            "enoughMemory"  to enoughMemory,
            "apiLevel"      to apiLevel,
            "abi"           to abi,
            "reason"        to when {
                !supported     -> "Android API $apiLevel < 26 (Android 8.0)"
                !enoughStorage -> "Insufficient free storage (need ≥700 MB)"
                !enoughMemory  -> "Insufficient RAM (need ≥1.5 GB available)"
                else           -> null
            }
        ))
    }

    private fun checkFreeStorage(requiredBytes: Long): Boolean {
        return try {
            val stat = StatFs(context.filesDir.absolutePath)
            stat.availableBlocksLong * stat.blockSizeLong >= requiredBytes
        } catch (e: Exception) { true } // optimistic if check fails
    }

    private fun checkAvailableRam(requiredBytes: Long): Boolean {
        return try {
            val am  = context.getSystemService(Context.ACTIVITY_SERVICE)
                as ActivityManager
            val mi  = ActivityManager.MemoryInfo()
            am.getMemoryInfo(mi)
            mi.availMem >= requiredBytes
        } catch (e: Exception) { true }
    }

    // ─── EventChannel.StreamHandler ───────────────────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        generationJob?.cancel()
    }

    // ─── dispose ──────────────────────────────────────────────────────────────

    private fun disposeLlm() {
        try {
            llmInference?.javaClass?.getMethod("close")?.invoke(llmInference)
        } catch (_: Exception) {}
        llmInference = null
    }
}
