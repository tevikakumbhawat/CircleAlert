package usecase

import models.*
import repository.GeofenceRepository
import repository.GroupRepository

class ConfigureGeofenceUseCase(
    private val geofenceRepository: GeofenceRepository,
    private val groupRepository: GroupRepository
) {
    suspend operator fun invoke(
        groupId: String,
        name: String,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double,
        creatorId: String,
        currentEpochMs: Long
    ): CircleAlertResult<GeofenceConfig> {
        val trimmedName = name.trim()
        if (trimmedName.isEmpty()) {
            return CircleAlertResult.Error(CircleAlertException.GeofenceValidationException("Geofence name cannot be empty."))
        }

        if (!GeofenceConfig.isValidCoordinate(latitude, longitude)) {
            return CircleAlertResult.Error(CircleAlertException.GeofenceValidationException("Coordinates are out of bounds (lat: -90..90, lon: -180..180)."))
        }

        if (!GeofenceConfig.isValidRadius(radiusMeters)) {
            return CircleAlertResult.Error(CircleAlertException.GeofenceValidationException("Radius must be between ${GeofenceConfig.MIN_RADIUS_METERS.toInt()}m and ${GeofenceConfig.MAX_RADIUS_METERS.toInt()}m."))
        }

        val geofenceId = "geo_${groupId}_${currentEpochMs}"
        val geofenceConfig = GeofenceConfig(
            id = geofenceId,
            groupId = groupId,
            name = trimmedName,
            latitude = latitude,
            longitude = longitude,
            radiusMeters = radiusMeters,
            createdBy = creatorId,
            createdAtEpochMs = currentEpochMs,
            isActive = true
        )

        // Save geofence configuration
        val saveResult = geofenceRepository.saveGeofence(geofenceConfig)
        if (saveResult is CircleAlertResult.Error) {
            return saveResult
        }

        // Link geofence with tracking group
        val linkResult = groupRepository.updateGroupGeofence(groupId, geofenceId)
        if (linkResult is CircleAlertResult.Error) {
            return CircleAlertResult.Error(linkResult.exception)
        }

        return CircleAlertResult.Success(geofenceConfig)
    }
}
