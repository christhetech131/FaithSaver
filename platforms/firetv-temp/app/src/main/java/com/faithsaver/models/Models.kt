package com.faithsaver.firetv.models

/**
 * Represents an image item from the GitHub repository
 */
data class ImageItem(
    val name: String,
    val url: String,
    val category: String
)

/**
 * Represents a category of images
 */
enum class Category(val displayName: String, val folderName: String) {
    ANIMALS("Animals", "animals"),
    FALL("Fall", "fall"),
    GEOLOGY("Geology", "geology"),
    SCENERY("Scenery", "scenery"),
    SEASONAL("Seasonal", "seasonal"),
    SPACE("Space", "space"),
    SPRING("Spring", "spring"),
    SUMMER("Summer", "summer"),
    TEXTURES("Textures", "textures"),
    WINTER("Winter", "winter");
    
    companion object {
        fun fromFolderName(name: String): Category {
            return values().find { it.folderName == name } ?: SCENERY
        }
        
        fun getAll(): List<Category> = values().toList()
    }
}
