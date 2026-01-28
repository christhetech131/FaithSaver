package com.faithsaver.firetv.utils

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.util.LruCache
import com.faithsaver.firetv.models.Category

/**
 * Manages user preferences using SharedPreferences
 */
class PreferencesManager(context: Context) {
    
    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    
    companion object {
        private const val PREFS_NAME = "FaithSaverPrefs"
        private const val KEY_SELECTED_CATEGORY = "selected_category"
        private const val DEFAULT_CATEGORY = "scenery"
    }
    
    fun getSelectedCategory(): String {
        return prefs.getString(KEY_SELECTED_CATEGORY, DEFAULT_CATEGORY) ?: DEFAULT_CATEGORY
    }
    
    fun setSelectedCategory(category: String) {
        prefs.edit().putString(KEY_SELECTED_CATEGORY, category).apply()
    }
    
    fun getSelectedCategoryEnum(): Category {
        return Category.fromFolderName(getSelectedCategory())
    }
}

/**
 * In-memory image cache using LRU strategy
 */
class ImageCache(context: Context) {
    
    private val cache: LruCache<String, Bitmap>
    
    init {
        // Get max available VM memory, exceeding this amount will throw an OutOfMemory exception
        val maxMemory = (Runtime.getRuntime().maxMemory() / 1024).toInt()
        
        // Use 1/8th of the available memory for this memory cache
        val cacheSize = maxMemory / 8
        
        cache = object : LruCache<String, Bitmap>(cacheSize) {
            override fun sizeOf(key: String, bitmap: Bitmap): Int {
                // Cache size measured in kilobytes rather than number of items
                return bitmap.byteCount / 1024
            }
        }
    }
    
    fun put(key: String, bitmap: Bitmap) {
        if (get(key) == null) {
            cache.put(key, bitmap)
        }
    }
    
    fun get(key: String): Bitmap? {
        return cache.get(key)
    }
    
    fun clear() {
        cache.evictAll()
    }
    
    fun size(): Int {
        return cache.size()
    }
}
