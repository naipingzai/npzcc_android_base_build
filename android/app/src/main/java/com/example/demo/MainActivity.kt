package com.example.demo

import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.demo.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityMainBinding
    private val nativeLib = NativeLib()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupUI()
        demonstrateNDK()
    }
    
    private fun setupUI() {
        // 基础Native调用
        binding.btnBasicNative.setOnClickListener {
            val message = nativeLib.helloFromNative()
            binding.tvResult.text = "基础Native调用结果:\n$message"
            showToast("Native调用成功!")
        }
        
        // 系统信息
        binding.btnSystemInfo.setOnClickListener {
            val info = nativeLib.getSystemInfo()
            binding.tvResult.text = info
            showToast("获取系统信息成功!")
        }
    }
    
    private fun demonstrateNDK() {
        val welcomeText = """
            NDK Demo 应用
        """.trimIndent()
        
        binding.tvResult.text = welcomeText
    }

    private fun showToast(message: String) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
    }
}