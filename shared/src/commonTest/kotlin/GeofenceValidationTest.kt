import models.GeofenceConfig
import utils.LocationUtils
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class GeofenceValidationTest {

    @Test
    fun testValidCoordinates() {
        assertTrue(GeofenceConfig.isValidCoordinate(37.7749, -122.4194)) // San Francisco
        assertTrue(GeofenceConfig.isValidCoordinate(0.0, 0.0))
        assertTrue(GeofenceConfig.isValidCoordinate(90.0, 180.0))
        assertTrue(GeofenceConfig.isValidCoordinate(-90.0, -180.0))

        assertFalse(GeofenceConfig.isValidCoordinate(90.1, 0.0))
        assertFalse(GeofenceConfig.isValidCoordinate(-90.1, 0.0))
        assertFalse(GeofenceConfig.isValidCoordinate(0.0, 180.1))
        assertFalse(GeofenceConfig.isValidCoordinate(0.0, -180.1))
    }

    @Test
    fun testValidRadius() {
        assertTrue(GeofenceConfig.isValidRadius(50.0))
        assertTrue(GeofenceConfig.isValidRadius(500.0))
        assertTrue(GeofenceConfig.isValidRadius(10000.0))

        assertFalse(GeofenceConfig.isValidRadius(49.9))
        assertFalse(GeofenceConfig.isValidRadius(0.0))
        assertFalse(GeofenceConfig.isValidRadius(-100.0))
        assertFalse(GeofenceConfig.isValidRadius(10000.1))
    }

    @Test
    fun testHaversineDistanceCalculation() {
        // Distance between SF Ferry Building and Coit Tower ~ 1.4 km (1400m)
        val sfFerryLat = 37.7955
        val sfFerryLon = -122.3937
        val coitTowerLat = 37.8024
        val coitTowerLon = -122.4058

        val distance = LocationUtils.calculateDistanceMeters(
            sfFerryLat, sfFerryLon,
            coitTowerLat, coitTowerLon
        )

        assertTrue(distance in 1200.0..1600.0, "Expected ~1400m distance, got $distance")
    }

    @Test
    fun testInsideGeofenceCheck() {
        val centerLat = 37.7749
        val centerLon = -122.4194
        val radius = 250.0 // 250 meters

        // Point very close to center (~10m)
        val insidePointLat = 37.77495
        val insidePointLon = -122.41945
        assertTrue(
            LocationUtils.isPointInsideGeofence(
                insidePointLat, insidePointLon,
                centerLat, centerLon, radius
            )
        )
        assertEquals(0.0, LocationUtils.distanceOutsideGeofence(
            insidePointLat, insidePointLon,
            centerLat, centerLon, radius
        ))

        // Point far outside (~1.5km away)
        val outsidePointLat = 37.7900
        val outsidePointLon = -122.4194
        assertFalse(
            LocationUtils.isPointInsideGeofence(
                outsidePointLat, outsidePointLon,
                centerLat, centerLon, radius
            )
        )
        val distOutside = LocationUtils.distanceOutsideGeofence(
            outsidePointLat, outsidePointLon,
            centerLat, centerLon, radius
        )
        assertTrue(distOutside > 1000.0, "Distance outside should be > 1000m, got $distOutside")
    }
}
