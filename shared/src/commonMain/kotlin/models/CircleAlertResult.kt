package models

sealed class CircleAlertResult<out T> {
    data class Success<out T>(val data: T) : CircleAlertResult<T>()
    data class Error(val exception: CircleAlertException) : CircleAlertResult<Nothing>()

    val isSuccess: Boolean get() = this is Success
    val isError: Boolean get() = this is Error

    fun getOrNull(): T? = when (this) {
        is Success -> data
        is Error -> null
    }

    fun exceptionOrNull(): CircleAlertException? = when (this) {
        is Success -> null
        is Error -> exception
    }
}

sealed class CircleAlertException(message: String, cause: Throwable? = null) : Exception(message, cause) {
    class InvalidGroupNameException(msg: String = "Group name must be between 3 and 50 characters.") : CircleAlertException(msg)
    class InvalidInviteCodeException(msg: String = "Invite code must be 6 alphanumeric characters.") : CircleAlertException(msg)
    class GroupNotFoundException(msg: String = "Group with specified invite code was not found.") : CircleAlertException(msg)
    class MemberAlreadyExistsException(msg: String = "User is already a member of this group.") : CircleAlertException(msg)
    class GeofenceValidationException(msg: String = "Invalid geofence parameters.") : CircleAlertException(msg)
    class UnauthorizedException(msg: String = "User is not authorized for this action.") : CircleAlertException(msg)
    class NetworkException(msg: String = "Network communication error occurred.", cause: Throwable? = null) : CircleAlertException(msg, cause)
    class GenericException(msg: String, cause: Throwable? = null) : CircleAlertException(msg, cause)
}
