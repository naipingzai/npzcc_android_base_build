package com.example.demo

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.example.demo.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityMainBinding
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        // 设置点击事件
        binding.buttonHello.setOnClickListener {
            binding.textViewMessage.text = "Hello, Android!"
        }
        
        // 设置悬浮按钮点击事件
        binding.fab.setOnClickListener {
            binding.textViewMessage.text = "Floating Action Button clicked!"
        }
    }
}