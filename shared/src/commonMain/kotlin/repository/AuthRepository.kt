package repository

import kotlinx.coroutines.flow.StateFlow
import models.CircleAlertResult
import models.User

interface AuthRepository {
    val currentUserFlow: StateFlow<User?>
    fun getCurrentUser(): User?

    suspend fun signIn(email: String, password: String): CircleAlertResult<User>
    suspend fun signUp(email: String, password: String, displayName: String): CircleAlertResult<User>
    suspend fun signOut(): CircleAlertResult<Unit>
    suspend fun updatePushToken(token: String): CircleAlertResult<Unit>
}
