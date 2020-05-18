package com.vijesh.password_tracker

import com.vijesh.password_tracker.CryptoHelper
import javax.crypto.Cipher
import android.content.Context.MODE_PRIVATE
import android.content.Context
import java.security.Signature


class SecureLocalManager(ctxt: Context) {
    private var release = true;
    companion object {
        const val SHARED_PREFERENCES_NAME = "settings"
        const val APPLICATION_KEY_NAME = "ApplicationKey"
        const val SECRET_TEXT_NAME = "Secret"
        const val IV_SIZE = 16
    }

    private var keystoreManager: KeystoreManager
    private var cryptoHelper: CryptoHelper
    private lateinit var applicationKey : ByteArray
    private var applicationContext : Context

    init {
        applicationContext = ctxt
        cryptoHelper = CryptoHelper()
        keystoreManager = KeystoreManager(applicationContext, cryptoHelper)
        keystoreManager.generateMasterKeys()
    }

    fun log(str: String) {
        if (release) {
            return;
        }
        println(str);
    }

    fun encryptLocalData(data: ByteArray):ByteArray {
        val iv = cryptoHelper.generateIV(IV_SIZE)
        val s = String(applicationKey)
        log("application key in encrypt = $s")
        return iv + cryptoHelper.encryptData(data, applicationKey, iv)
    }

    fun decryptLocalData(data: ByteArray):ByteArray {
        val iv = data.sliceArray(0 .. IV_SIZE-1)
        val ct = data.sliceArray(IV_SIZE.. data.lastIndex)
        val s = String(applicationKey)
        log("application key in decrypt = $s")
        return cryptoHelper.decryptData(ct, applicationKey, iv)
    }

    fun getLocalEncryptionCipher():Cipher{
        return keystoreManager.getLocalEncryptionCipher()
    }

    fun loadOrGenerateApplicationKey(cipher: Cipher){
        val preferences = applicationContext.getSharedPreferences(SHARED_PREFERENCES_NAME, MODE_PRIVATE)
        log("inside load or generate")
        if (preferences.contains(APPLICATION_KEY_NAME)) {
            log("inside contains success")
            val encryptedAppKey = preferences.getString(APPLICATION_KEY_NAME, "")!!
            applicationKey = keystoreManager.decryptApplicationKey(cryptoHelper.hexToByteArray(encryptedAppKey), cipher)
        }
        else{
            log("inside contains failure")
            applicationKey = cryptoHelper.generateApplicationKey()
            val editor = preferences.edit()
            val encryptedAppKey = cryptoHelper.byteArrayToHex(keystoreManager.encryptApplicationKey(applicationKey, cipher))
            editor.putString(APPLICATION_KEY_NAME, encryptedAppKey)
            editor.apply()
        }
    }

    fun getSignature(): Signature {
        return keystoreManager.getSignature()
    }

    fun signData(data: ByteArray, signature: Signature): ByteArray {
        signature.update(data)
        return signature.sign()
    }

    fun verifyDataSignature(dataSigned: ByteArray, data: ByteArray): Boolean {
        return keystoreManager.verifySignature(dataSigned, data)
    }
}