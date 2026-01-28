package com.faithsaver.firetv.network

import android.util.Log
import com.faithsaver.firetv.models.ImageItem
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

class GitHubApiClient {
    
    companion object {
        private const val TAG = "GitHubApiClient"
        private const val REPO_OWNER = "christhetech131"
        private const val REPO_NAME = "FaithSaver"
        private const val BASE_API_URL = "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents"
        
        private val VALID_EXTENSIONS = setOf("jpg", "jpeg", "png")
    }
    
    /**
     * Fetches the list of images for a given category from GitHub
     * @param category The category folder name (e.g., "animals", "scenery")
     * @return List of ImageItem objects with URLs to the raw images
     */
    fun fetchImagesForCategory(category: String): List<ImageItem> {
        val imageItems = mutableListOf<ImageItem>()
        val url = "$BASE_API_URL/$category"
        
        try {
            Log.d(TAG, "Fetching from: $url")
            
            val connection = URL(url).openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.setRequestProperty("Accept", "application/vnd.github.v3+json")
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            
            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val response = BufferedReader(InputStreamReader(connection.inputStream)).use {
                    it.readText()
                }
                
                val jsonArray = JSONArray(response)
                
                for (i in 0 until jsonArray.length()) {
                    val item = jsonArray.getJSONObject(i)
                    
                    // Only process files (not directories)
                    if (item.getString("type") == "file") {
                        val name = item.getString("name")
                        val extension = name.substringAfterLast('.', "").toLowerCase()
                        
                        if (extension in VALID_EXTENSIONS) {
                            val downloadUrl = item.getString("download_url")
                            imageItems.add(
                                ImageItem(
                                    name = name,
                                    url = downloadUrl,
                                    category = category
                                )
                            )
                        }
                    }
                }
                
                Log.d(TAG, "Found ${imageItems.size} images in category: $category")
            } else {
                Log.e(TAG, "HTTP error: $responseCode")
            }
            
            connection.disconnect()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error fetching images for category: $category", e)
        }
        
        return imageItems
    }
}
