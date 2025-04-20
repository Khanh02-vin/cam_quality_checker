package com.example.orange_quality_checker

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

// This class is application entry point for Flutter engine
class MainApplication : Application() {
    companion object {
        private const val ENGINE_ID = "orange_quality_checker_engine"
    }
    
    private var flutterEngine: FlutterEngine? = null

    override fun onCreate() {
        super.onCreate()
        
        // Pre-initialize flutter engine for faster startup
        initFlutterEngine()
    }
    
    private fun initFlutterEngine() {
        // Create and configure a FlutterEngine
        flutterEngine = FlutterEngine(this).apply {
            dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
            
            // Cache the engine for later use
            FlutterEngineCache.getInstance().put(ENGINE_ID, this)
        }
    }
} 