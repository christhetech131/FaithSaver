package com.faithsaver.firetv

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

class MainActivity : Activity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        
        setupViews()
    }
    
    private fun setupViews() {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(80, 80, 80, 80)
            setBackgroundColor(0xFF1a1a1a.toInt())
        }
        
        val title = TextView(this).apply {
            text = "FaithSaver"
            textSize = 56f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 60)
        }
        layout.addView(title)
        
        val subtitle = TextView(this).apply {
            text = "Faith-Based Photo Slideshow"
            textSize = 24f
            setTextColor(0xFFCCCCCC.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 80)
        }
        layout.addView(subtitle)
        
        val startButton = createButton("Start Slideshow") {
            startActivity(Intent(this, SlideshowActivity::class.java))
        }
        layout.addView(startButton)
        
        val settingsButton = createButton("Settings") {
            startActivity(Intent(this, SettingsActivity::class.java))
        }
        layout.addView(settingsButton)
        
        val submitButton = createButton("Submit Images") {
            showQRCodeDialog()
        }
        layout.addView(submitButton)
        
        val instructions = TextView(this).apply {
            text = "• Use D-pad to navigate\n• Press SELECT to choose\n• Press BACK to exit slideshow"
            textSize = 18f
            setTextColor(0xFF999999.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 60, 0, 0)
        }
        layout.addView(instructions)
        
        setContentView(layout)
    }
    
    private fun createButton(text: String, onClick: () -> Unit): Button {
        return Button(this).apply {
            this.text = text
            textSize = 28f
            setPadding(60, 30, 60, 30)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 30
            }
            setOnClickListener { onClick() }
            
            isFocusable = true
            isFocusableInTouchMode = true
        }
    }
    
    private fun showQRCodeDialog() {
        val dialogLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(40, 40, 40, 40)
            gravity = Gravity.CENTER
        }
        
        val titleText = TextView(this).apply {
            text = "Submit Your Faith-Based Images"
            textSize = 22f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 20)
        }
        dialogLayout.addView(titleText)
        
        val qrImage = ImageView(this).apply {
            setImageResource(R.drawable.qr_code)
            layoutParams = LinearLayout.LayoutParams(
                400,
                400
            ).apply {
                topMargin = 20
                bottomMargin = 20
            }
        }
        dialogLayout.addView(qrImage)
        
        val instructions = TextView(this).apply {
            text = "Scan this QR code with your phone\nto submit images to our GitHub repository"
            textSize = 16f
            setTextColor(0xFFCCCCCC.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 20, 0, 0)
        }
        dialogLayout.addView(instructions)
        
        val scrollView = android.widget.ScrollView(this)
        scrollView.addView(dialogLayout)
        
        AlertDialog.Builder(this)
            .setTitle("Submit Images")
            .setView(scrollView)
            .setPositiveButton("Close") { dialog, _ ->
                dialog.dismiss()
            }
            .show()
    }
}
