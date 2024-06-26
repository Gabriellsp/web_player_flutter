package com.example.web_player_flutter

import android.app.PictureInPictureParams
import android.os.Build
import android.os.Bundle
import android.util.Rational // Importe a classe Rational diretamente do pacote android.util
import androidx.annotation.NonNull
import androidx.appcompat.app.AppCompatActivity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.seventh/pip"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "enterPictureInPictureMode") {
                enterPipMode()
                result.success(null)
            } else if (call.method == "isPIP"){
                val isInPipMode = isInPictureInPictureMode // Verifica se está no modo PiP
                result.success(isInPipMode)
            } else{
                result.notImplemented()
            }
        }
    }

    private fun enterPipMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val aspectRatio = Rational(16, 9)
            val pipBuilder = PictureInPictureParams.Builder()
            pipBuilder.setAspectRatio(aspectRatio)
            enterPictureInPictureMode(pipBuilder.build())
        }
    }
    
}
