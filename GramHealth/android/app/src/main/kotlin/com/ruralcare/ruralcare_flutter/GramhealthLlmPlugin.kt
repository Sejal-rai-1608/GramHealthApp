package com.gramhealth

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.StatFs
import android.util.Log
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
 * Native Android plugin for LiteRT-LM / MediaPipe on-device inference.
 *
 * Method channel:  gramhealth/offline_llm
 * Event channel:   gramhealth/offline_llm_tokens
 */
class GramhealthLlmPlugin : FlutterPlugin, MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        private const val TAG = "GramhealthLlm"
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var context: Context

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var generationJob: Job? = null

    // LlmInference instance — loaded lazily via reflection
    private var llmInference: Any? = null

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

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "generate"   -> handleGenerate(call, result)
            "cancel"     -> handleCancel(result)
            "dispose"    -> { disposeLlm(); result.success(null) }
            "checkCompatibility" -> handleCompatibility(result)
            "runSmokeTest" -> handleSmokeTest(call, result)
            else -> result.notImplemented()
        }
    }

    // ─── initialize ──────────────────────────────────────────────────────────

    private fun handleInitialize(call: MethodCall, result: Result) {
        val modelPath = call.argument<String>("modelPath")
            ?: return result.error("INVALID_ARGS", "modelPath required", null)
        val maxTokens  = call.argument<Int>("maxTokens")   ?: 400
        val temperature = call.argument<Double>("temperature") ?: 0.2
        val topK        = call.argument<Int>("topK")       ?: 40

        scope.launch {
            try {
                val file = File(modelPath)
                val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                val mi = ActivityManager.MemoryInfo()
                am?.getMemoryInfo(mi)

                Log.i(TAG, "=== Native Model Initialization Requested ===")
                Log.i(TAG, "Device: ${Build.MANUFACTURER} ${Build.MODEL} (SDK ${Build.VERSION.SDK_INT}, ABI ${Build.SUPPORTED_ABIS?.firstOrNull()})")
                Log.i(TAG, "RAM: ${mi.availMem / 1024 / 1024} MB avail / ${mi.totalMem / 1024 / 1024} MB total")
                Log.i(TAG, "Model: $modelPath (size: ${if (file.exists()) file.length() else -1} bytes)")
                Log.i(TAG, "Backend: CPU (enforcing safe mode)")

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

                // Force safe CPU backend
                try {
                    val backendClass = Class.forName(
                        "com.google.mediapipe.tasks.genai.llminference.LlmInference\$Backend"
                    )
                    val cpuBackend = java.lang.Enum.valueOf(backendClass as Class<out Enum<*>>, "CPU")
                    builderClass.getMethod("setPreferredBackend", backendClass)
                        .invoke(builderInstance, cpuBackend)
                    Log.i(TAG, "Forced preferred backend to CPU")
                } catch (e: Exception) {
                    Log.w(TAG, "Could not set CPU backend on builder: $e")
                }

                val options = builderClass.getMethod("build")
                    .invoke(builderInstance)
                llmInference = llmClass
                    .getMethod("createFromOptions",
                        Context::class.java,
                        optionsClass)
                    .invoke(null, context, options)

                Log.i(TAG, "Native LlmInference session created successfully.")
                withContext(Dispatchers.Main) { result.success(null) }
            } catch (e: ClassNotFoundException) {
                Log.e(TAG, "MediaPipe dependency missing: $e")
                withContext(Dispatchers.Main) {
                    result.error(
                        "LLM_DEPENDENCY_MISSING",
                        "com.google.mediapipe:tasks-genai is not on the classpath.",
                        e.toString()
                    )
                }
            } catch (e: Exception) {
                Log.e(TAG, "Native LLM init failed: $e")
                withContext(Dispatchers.Main) {
                    result.error("LLM_INIT_FAILED", e.message, e.toString())
                }
            }
        }
    }

    // ─── smoke test ──────────────────────────────────────────────────────────

    private fun handleSmokeTest(call: MethodCall, result: Result) {
        val modelPath = call.argument<String>("modelPath")
            ?: return result.error("INVALID_ARGS", "modelPath required", null)
        val testPrompt = call.argument<String>("testPrompt") ?: "Say OK"

        scope.launch {
            try {
                Log.i(TAG, "=== Running Isolated Native Smoke Test ===")
                Log.i(TAG, "Model: $modelPath | Prompt: '$testPrompt' | maxTokens: 32 | Backend: CPU")

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
                    .invoke(builderInstance, 32)

                // Force safe CPU backend
                try {
                    val backendClass = Class.forName(
                        "com.google.mediapipe.tasks.genai.llminference.LlmInference\$Backend"
                    )
                    val cpuBackend = java.lang.Enum.valueOf(backendClass as Class<out Enum<*>>, "CPU")
                    builderClass.getMethod("setPreferredBackend", backendClass)
                        .invoke(builderInstance, cpuBackend)
                    Log.i(TAG, "Smoke test: forced CPU backend")
                } catch (e: Exception) {
                    Log.w(TAG, "Smoke test: setPreferredBackend(CPU) not available: $e")
                }

                val options = builderClass.getMethod("build")
                    .invoke(builderInstance)
                val testLlm = llmClass
                    .getMethod("createFromOptions",
                        Context::class.java,
                        optionsClass)
                    .invoke(null, context, options)

                val genMethod = testLlm.javaClass.getMethod("generate", String::class.java)
                val response = genMethod.invoke(testLlm, testPrompt) as? String ?: ""
                Log.i(TAG, "Smoke test response received: '$response'")

                try {
                    testLlm.javaClass.getMethod("close").invoke(testLlm)
                } catch (_: Exception) {}

                withContext(Dispatchers.Main) {
                    result.success(mapOf(
                        "success" to true,
                        "response" to response,
                        "backend" to "cpu",
                        "device" to "${Build.MANUFACTURER} ${Build.MODEL}"
                    ))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Smoke test failed: $e")
                withContext(Dispatchers.Main) {
                    result.success(mapOf(
                        "success" to false,
                        "error" to (e.message ?: e.toString()),
                        "backend" to "cpu",
                        "device" to "${Build.MANUFACTURER} ${Build.MODEL}"
                    ))
                }
            }
        }
    }

    // ─── generate ────────────────────────────────────────────────────────────

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
        return "<|im_start|>system\n$system<|im_end|>\n" +
               "<|im_start|>user\n$user<|im_end|>\n" +
               "<|im_start|>assistant\n"
    }

    // ─── cancel ──────────────────────────────────────────────────────────────

    private fun handleCancel(result: Result) {
        generationJob?.cancel()
        generationJob = null
        scope.launch(Dispatchers.Main) {
            eventSink?.success("__EOS__")
        }
        result.success(null)
    }

    // ─── compatibility ───────────────────────────────────────────────────────

    private fun handleCompatibility(result: Result) {
        val apiLevel   = Build.VERSION.SDK_INT
        val apiSupported = apiLevel >= 26
        val enoughStorage = checkFreeStorage(700_000_000L)
        val enoughMemory  = checkAvailableRam(1_500_000_000L)
        val abis = Build.SUPPORTED_ABIS ?: emptyArray()
        val supportedAbi = abis.contains("arm64-v8a")
        val abi = abis.firstOrNull() ?: "unknown"
        val manufacturer = Build.MANUFACTURER ?: "unknown"
        val model = Build.MODEL ?: "unknown"

        val am  = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
        val mi  = ActivityManager.MemoryInfo()
        am?.getMemoryInfo(mi)
        val availMem = mi.availMem
        val totalMem = mi.totalMem

        var nativeRuntimeSupported = false
        try {
            Class.forName("com.google.mediapipe.tasks.genai.llminference.LlmInference")
            nativeRuntimeSupported = true
        } catch (_: Exception) {}

        val supported = apiSupported && supportedAbi

        Log.i(TAG, "Device diagnostics: $manufacturer $model, SDK=$apiLevel, ABI=$abi, " +
            "RAM=${availMem / 1024 / 1024}MB / ${totalMem / 1024 / 1024}MB, NativeRuntime=$nativeRuntimeSupported, Backend=CPU")

        result.success(mapOf(
            "supported"              to supported,
            "enoughStorage"          to enoughStorage,
            "enoughMemory"           to enoughMemory,
            "supportedAbi"           to supportedAbi,
            "nativeRuntimeSupported" to nativeRuntimeSupported,
            "modelFormatSupported"   to true,
            "runtimeVersionSupported" to true,
            "backendSupported"       to true,
            "smokeTestPassed"        to false,
            "manufacturer"           to manufacturer,
            "deviceModel"            to model,
            "apiLevel"               to apiLevel,
            "abi"                    to abi,
            "availableRam"           to availMem,
            "totalRam"               to totalMem,
            "runtimeVersion"         to "0.10.14",
            "selectedBackend"        to "cpu",
            "reason"                 to when {
                !apiSupported           -> "Android API $apiLevel < 26 (Android 8.0)"
                !supportedAbi           -> "Device ABI '$abi' does not support arm64-v8a"
                !enoughStorage          -> "Insufficient free storage (need ≥700 MB)"
                !enoughMemory           -> "Insufficient RAM (need ≥1.5 GB available)"
                !nativeRuntimeSupported -> "MediaPipe LLM Inference native runtime not found on classpath"
                else                    -> null
            }
        ))
    }

    private fun checkFreeStorage(requiredBytes: Long): Boolean {
        return try {
            val stat = StatFs(context.filesDir.absolutePath)
            stat.availableBlocksLong * stat.blockSizeLong >= requiredBytes
        } catch (e: Exception) { true }
    }

    private fun checkAvailableRam(requiredBytes: Long): Boolean {
        return try {
            val am  = context.getSystemService(Context.ACTIVITY_SERVICE)
                as? ActivityManager
            val mi  = ActivityManager.MemoryInfo()
            am?.getMemoryInfo(mi)
            mi.availMem >= requiredBytes
        } catch (e: Exception) { true }
    }

    // ─── EventChannel.StreamHandler ──────────────────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        generationJob?.cancel()
    }

    // ─── dispose ─────────────────────────────────────────────────────────────

    private fun disposeLlm() {
        try {
            llmInference?.javaClass?.getMethod("close")?.invoke(llmInference)
        } catch (_: Exception) {}
        llmInference = null
    }
}