package com.example.trialpaymentapp.data

data class Account(
    val balanceCents: Long = 0,
    val updatedAt: com.google.firebase.Timestamp? = null
)

data class UserCard(
    val publicKeyPem: String = "",
    val keyId: String = "k1",
    val displayName: String = "",
    val updatedAt: com.google.firebase.Timestamp? = null
)

data class RemoteTxn(
    val id: String = "",
    val sender: String = "",
    val receiver: String = "",
    val amountCents: Long = 0,
    val timestamp: com.google.firebase.Timestamp? = null,
    val status: String = "PENDING"
)
