package com.vijesh.password_tracker

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle

import android.hardware.biometrics.BiometricPrompt
import androidx.core.hardware.fingerprint.FingerprintManagerCompat
import android.util.Base64
import com.vijesh.password_tracker.biometrix.BiometricCallback
import com.vijesh.password_tracker.biometrix.BiometricManager
import android.widget.Toast
import java.lang.Exception
import java.util.concurrent.locks.Condition
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

class MainActivity: BiometricCallback, FlutterActivity() {
    private val CHANNEL = "vijesh.flutter.dev/fingerprint"
    private var secureLocalManager: SecureLocalManager? = null;
    private lateinit var methodChannel: MethodChannel
    private var isEncrypt = false;
    private lateinit var text: String
    companion object {
        var release = true;

    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        log("configure flutter engine")
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler {
            call, result ->
            log("Inside invoke method 2 = ${call.method}")
            if (null == secureLocalManager) {
                secureLocalManager = SecureLocalManager(applicationContext)
            }
            if (call.method == "encrypt") {

                val text = call.argument<String>("text");
                try {
                    encrypt(data = text)
                    log("text  encrypt = $text")
                    result.success("SUCCESS")
                }catch (e:Exception) {
                    e.printStackTrace()
                    log("Going to clear shared preferences")
                    secureLocalManager!!.clearKeys()
                    result.error("ERROR","UNEXPECTED-ERROR", null);
                }
            } else if(call.method == "decrypt"){
                val text = call.argument<String>("text");
                try {
                    decrypt(data = text)
                    log("text decrypt = $text")
                    result.success("SUCCESS")
                }catch (e:Exception) {
                    e.printStackTrace();
                    log("Going to clear shared preferences")
                    secureLocalManager!!.clearKeys()
                    result.error("ERROR","UNEXPECTED-ERROR", null);
                }
            } else {
                result.notImplemented()
            }
            log("End of native function")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?){
        super.onCreate(savedInstanceState)
        // secureLocalManager = SecureLocalManager(applicationContext)
    }

    fun log(str: String) {
        if (release) {
            return;
        }
        println(str);
    }

    private fun encrypt(data: String?) {
        if (null != data) {
            text = data
            isEncrypt = true;
            authenticate()
        }
    }

    private fun decrypt(data: String?) {
        if (null != data) {
            text = data
            isEncrypt = false;
            authenticate()
        }
    }

    fun encryptData() {
        val encrypted = secureLocalManager?.encryptLocalData(text.toByteArray(Charsets.UTF_8))
        val b64 = Base64.encodeToString(encrypted, Base64.NO_WRAP)
        log("encrypted successfully")
        methodChannel.invokeMethod("successCallback",b64)
    }

    fun decryptData() {
        var decrStr = ""
        val decrypted = secureLocalManager?.decryptLocalData(Base64.decode(text, Base64.NO_WRAP))
        if (null != decrypted) {
            decrStr = String(decrypted, Charsets.UTF_8);
        }
        methodChannel.invokeMethod("successCallback", decrypted?.let { String(it) })
    }

    private fun authenticate(){
        val cipher = secureLocalManager?.getLocalEncryptionCipher()

        if (cipher != null) {
            BiometricManager.BiometricBuilder(this@MainActivity)
                    .setTitle("Authorise")
                    .setSubtitle("Please, authorise yourself")
                    .setDescription("This is needed to perform cryptographic operations.")
                    .setNegativeButtonText("Cancel")
                    .setCipher(cipher)
                    .build()
                    .authenticate(this@MainActivity)
        }
    }

    override fun onAuthenticationSuccessful(result: FingerprintManagerCompat.AuthenticationResult) {
        val cipher = result.cryptoObject.cipher!!
        log("Successful authentication finger print")
        secureLocalManager?.loadOrGenerateApplicationKey(cipher)
        try {
            if (isEncrypt) {
                encryptData()
            } else {
                decryptData()
            }
        }catch (e:Exception) {
            e.printStackTrace();
            log("exception while authentication")
            onBiometricAuthenticationInternalError("internal error");
            secureLocalManager?.clearKeys()
        }
    }

    override fun onAuthenticationSuccessful(result: BiometricPrompt.AuthenticationResult) {
        val cipher = result.cryptoObject.cipher!!
        log("successful authentication biometric")
        secureLocalManager?.loadOrGenerateApplicationKey(cipher)
        
        try {
            if (isEncrypt) {
                encryptData()
            } else {
                decryptData()
            }
        }catch (e:Exception) {
            e.printStackTrace();
            log("exception while authentication")
            onBiometricAuthenticationInternalError("internal error");
            secureLocalManager?.clearKeys()
        }
    }


    override fun onSdkVersionNotSupported() {
        methodChannel.invokeMethod("failureCallback","SDK-VERSION-NOT-SUPPORTED")
    }

    override fun onBiometricAuthenticationNotSupported() {
        methodChannel.invokeMethod("failureCallback","AUTH-NOT-SUPPORTED")
    }

    override fun onBiometricAuthenticationNotAvailable() {
        methodChannel.invokeMethod("failureCallback","AUTH-NOT-AVAILABLE")
    }

    override fun onBiometricAuthenticationPermissionNotGranted() {
        methodChannel.invokeMethod("failureCallback","PERM-NOT-GRANTED")
    }

    override fun onBiometricAuthenticationInternalError(error: String?) {
        methodChannel.invokeMethod("failureCallback","AUTH-INTERNAL-ERROR")
    }

    override fun onAuthenticationFailed() {
        methodChannel.invokeMethod("failureCallback","AUTH-FAILED")
    }

    override fun onAuthenticationCancelled() {
        methodChannel.invokeMethod("failureCallback","AUTH-CANCELLED")
    }

    override fun onAuthenticationHelp(helpCode: Int, helpString: CharSequence?) {
        methodChannel.invokeMethod("failureCallback","AUTH-HELP")
    }

    override fun onAuthenticationError(errorCode: Int, errString: CharSequence?) {
        methodChannel.invokeMethod("failureCallback","AUTH-ERROR")
    }
}
