package com.example.trialpaymentapp.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "user_profile")
data class UserProfile(
    @PrimaryKey val uid: String,
    val displayName: String,
    val keyId: String,
    val publicKeyPem: String
)
