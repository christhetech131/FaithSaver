package com.faithsaver.firetv

import android.app.Activity
import android.app.AlertDialog
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.*
import com.faithsaver.firetv.models.Category
import com.faithsaver.firetv.utils.PreferencesManager

class SettingsActivity : Activity() {
    
    private lateinit var prefsManager: PreferencesManager
    private lateinit var categoryListView: ListView
    private lateinit var aboutButton: Button
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        prefsManager = PreferencesManager(this)
        
        setupViews()
        loadCategories()
    }
    
    private fun setupViews() {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(40, 40, 40, 40)
        }
        
        val title = TextView(this).apply {
            text = "FaithSaver Settings"
            textSize = 28f
            setPadding(0, 0, 0, 32)
        }
        layout.addView(title)
        
        val subtitle = TextView(this).apply {
            text = "Select Image Category"
            textSize = 20f
            setPadding(0, 0, 0, 16)
        }
        layout.addView(subtitle)
        
        categoryListView = ListView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f
            )
        }
        layout.addView(categoryListView)
        
        aboutButton = Button(this).apply {
            text = "About FaithSaver"
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = 24
            }
            setOnClickListener { showAboutDialog() }
        }
        layout.addView(aboutButton)
        
        setContentView(layout)
    }
    
    private fun loadCategories() {
        val categories = Category.getAll()
        val currentCategory = prefsManager.getSelectedCategory()
        
        val adapter = object : ArrayAdapter<Category>(
            this,
            android.R.layout.simple_list_item_single_choice,
            categories
        ) {
            override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                val view = super.getView(position, convertView, parent)
                val textView = view.findViewById<TextView>(android.R.id.text1)
                textView.text = getItem(position)?.displayName
                textView.textSize = 18f
                return view
            }
        }
        
        categoryListView.adapter = adapter
        categoryListView.choiceMode = ListView.CHOICE_MODE_SINGLE
        
        val currentIndex = categories.indexOfFirst { it.folderName == currentCategory }
        if (currentIndex >= 0) {
            categoryListView.setItemChecked(currentIndex, true)
        }
        
        categoryListView.setOnItemClickListener { _, _, position, _ ->
            val selectedCategory = categories[position]
            prefsManager.setSelectedCategory(selectedCategory.folderName)
            Toast.makeText(
                this,
                "Selected: ${selectedCategory.displayName}",
                Toast.LENGTH_SHORT
            ).show()
        }
    }
    
    private fun showAboutDialog() {
        val message = buildString {
            appendLine("FaithSaver")
            appendLine("Version 1.0")
            appendLine()
            appendLine("A slideshow app that displays faith-based photography")
            appendLine("and Scripture artwork.")
            appendLine()
            appendLine("Categories include:")
            Category.getAll().forEach {
                appendLine("• ${it.displayName}")
            }
            appendLine()
            appendLine("Images rotate every 30 seconds with smooth transitions.")
            appendLine()
            appendLine("To submit your own faith-based images, click 'Submit Images'")
            appendLine("on the main screen and scan the QR code.")
            appendLine()
            appendLine("Press OK to close this dialog.")
        }
        
        val scrollView = ScrollView(this)
        val textView = TextView(this).apply {
            text = message
            textSize = 16f
            setPadding(40, 40, 40, 40)
        }
        scrollView.addView(textView)
        
        AlertDialog.Builder(this)
            .setTitle("About FaithSaver")
            .setView(scrollView)
            .setPositiveButton("OK") { dialog, _ ->
                dialog.dismiss()
            }
            .show()
    }
}
