package com.faithsaver.firetv

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ObjectAnimator
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import android.service.dreams.DreamService
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.RelativeLayout
import com.faithsaver.firetv.models.Category
import com.faithsaver.firetv.models.ImageItem
import com.faithsaver.firetv.network.GitHubApiClient
import com.faithsaver.firetv.utils.ImageCache
import com.faithsaver.firetv.utils.PreferencesManager
import kotlinx.coroutines.*
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL

class FaithSaverDream : DreamService() {

    private lateinit var container: RelativeLayout
    private lateinit var imageView1: ImageView
    private lateinit var imageView2: ImageView
    
    private var currentImageView: ImageView? = null
    private var nextImageView: ImageView? = null
    
    private val handler = Handler(Looper.getMainLooper())
    private var rotationRunnable: Runnable? = null
    
    private val imageItems = mutableListOf<ImageItem>()
    private var currentIndex = 0
    private var transitionType = TransitionType.FADE
    
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val apiClient = GitHubApiClient()
    private lateinit var imageCache: ImageCache
    private lateinit var prefsManager: PreferencesManager
    
    companion object {
        private const val TAG = "FaithSaverDream"
        private const val ROTATION_INTERVAL = 30000L // 30 seconds
        private const val TRANSITION_DURATION = 1000L // 1 second
    }
    
    enum class TransitionType {
        FADE, SLIDE, ZOOM
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        
        // Make it fullscreen
        isFullscreen = true
        isInteractive = false
        isScreenBright = true
        
        Log.d(TAG, "FaithSaver Dream starting")
        
        prefsManager = PreferencesManager(this)
        imageCache = ImageCache(this)
        
        setupViews()
        loadOfflineImage()
        startRotation()
        fetchOnlineImages()
    }
    
    private fun setupViews() {
        container = RelativeLayout(this)
        container.layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        
        // Create two image views for transitions
        imageView1 = createImageView()
        imageView2 = createImageView()
        
        container.addView(imageView1)
        container.addView(imageView2)
        
        currentImageView = imageView1
        nextImageView = imageView2
        
        setContentView(container)
    }
    
    private fun createImageView(): ImageView {
        val imageView = ImageView(this)
        imageView.layoutParams = RelativeLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        imageView.scaleType = ImageView.ScaleType.CENTER_CROP
        imageView.alpha = 0f
        return imageView
    }
    
    private fun loadOfflineImage() {
        try {
            val bitmap = BitmapFactory.decodeResource(resources, R.drawable.offline_default)
            currentImageView?.setImageBitmap(bitmap)
            currentImageView?.alpha = 1f
            Log.d(TAG, "Loaded offline default image")
        } catch (e: Exception) {
            Log.e(TAG, "Error loading offline image", e)
        }
    }
    
    private fun startRotation() {
        rotationRunnable = object : Runnable {
            override fun run() {
                if (imageItems.isNotEmpty()) {
                    loadAndShowNextImage()
                }
                handler.postDelayed(this, ROTATION_INTERVAL)
            }
        }
        handler.postDelayed(rotationRunnable!!, ROTATION_INTERVAL)
        Log.d(TAG, "Rotation timer started")
    }
    
    private fun fetchOnlineImages() {
        val selectedCategory = prefsManager.getSelectedCategory()
        Log.d(TAG, "Fetching images for category: $selectedCategory")
        
        scope.launch {
            try {
                val items = withContext(Dispatchers.IO) {
                    apiClient.fetchImagesForCategory(selectedCategory)
                }
                
                if (items.isNotEmpty()) {
                    imageItems.clear()
                    imageItems.addAll(items)
                    currentIndex = 0
                    Log.d(TAG, "Fetched ${items.size} images")
                    
                    // Start showing online images immediately
                    loadAndShowNextImage()
                } else {
                    Log.w(TAG, "No images found for category: $selectedCategory")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error fetching images", e)
            }
        }
    }
    
    private fun loadAndShowNextImage() {
        if (imageItems.isEmpty()) return
        
        val nextItem = imageItems[currentIndex]
        currentIndex = (currentIndex + 1) % imageItems.size
        
        // Cycle through transition types
        transitionType = TransitionType.values()[currentIndex % TransitionType.values().size]
        
        scope.launch {
            val bitmap = loadImageFromUrl(nextItem.url)
            if (bitmap != null) {
                showImageWithTransition(bitmap)
            }
        }
    }
    
    private suspend fun loadImageFromUrl(url: String): Bitmap? {
        return withContext(Dispatchers.IO) {
            try {
                // Check cache first
                imageCache.get(url)?.let { return@withContext it }
                
                // Download from network
                val connection = URL(url).openConnection() as HttpURLConnection
                connection.doInput = true
                connection.connect()
                
                val input: InputStream = connection.inputStream
                val bitmap = BitmapFactory.decodeStream(input)
                
                // Cache the bitmap
                bitmap?.let { imageCache.put(url, it) }
                
                bitmap
            } catch (e: Exception) {
                Log.e(TAG, "Error loading image from $url", e)
                null
            }
        }
    }
    
    private fun showImageWithTransition(bitmap: Bitmap) {
        val current = currentImageView ?: return
        val next = nextImageView ?: return
        
        next.setImageBitmap(bitmap)
        
        when (transitionType) {
            TransitionType.FADE -> fadeTransition(current, next)
            TransitionType.SLIDE -> slideTransition(current, next)
            TransitionType.ZOOM -> zoomTransition(current, next)
        }
        
        // Swap references
        currentImageView = next
        nextImageView = current
    }
    
    private fun fadeTransition(current: ImageView, next: ImageView) {
        next.alpha = 0f
        next.visibility = View.VISIBLE
        
        ObjectAnimator.ofFloat(next, "alpha", 0f, 1f).apply {
            duration = TRANSITION_DURATION
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    current.alpha = 0f
                    current.visibility = View.INVISIBLE
                }
            })
            start()
        }
    }
    
    private fun slideTransition(current: ImageView, next: ImageView) {
        val width = container.width.toFloat()
        
        next.alpha = 1f
        next.translationX = width
        next.visibility = View.VISIBLE
        
        // Slide in next
        ObjectAnimator.ofFloat(next, "translationX", width, 0f).apply {
            duration = TRANSITION_DURATION
            start()
        }
        
        // Slide out current
        ObjectAnimator.ofFloat(current, "translationX", 0f, -width).apply {
            duration = TRANSITION_DURATION
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    current.visibility = View.INVISIBLE
                    current.translationX = 0f
                }
            })
            start()
        }
    }
    
    private fun zoomTransition(current: ImageView, next: ImageView) {
        next.alpha = 0f
        next.scaleX = 1.2f
        next.scaleY = 1.2f
        next.visibility = View.VISIBLE
        
        // Zoom out and fade in next
        ObjectAnimator.ofFloat(next, "alpha", 0f, 1f).apply {
            duration = TRANSITION_DURATION
            start()
        }
        
        ObjectAnimator.ofFloat(next, "scaleX", 1.2f, 1f).apply {
            duration = TRANSITION_DURATION
            start()
        }
        
        ObjectAnimator.ofFloat(next, "scaleY", 1.2f, 1f).apply {
            duration = TRANSITION_DURATION
            start()
        }
        
        // Zoom in and fade out current
        ObjectAnimator.ofFloat(current, "alpha", 1f, 0f).apply {
            duration = TRANSITION_DURATION
            start()
        }
        
        ObjectAnimator.ofFloat(current, "scaleX", 1f, 1.3f).apply {
            duration = TRANSITION_DURATION
            start()
        }
        
        ObjectAnimator.ofFloat(current, "scaleY", 1f, 1.3f).apply {
            duration = TRANSITION_DURATION
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    current.visibility = View.INVISIBLE
                    current.scaleX = 1f
                    current.scaleY = 1f
                }
            })
            start()
        }
    }
    
    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        Log.d(TAG, "FaithSaver Dream stopping")
        
        rotationRunnable?.let { handler.removeCallbacks(it) }
        scope.cancel()
    }
}
