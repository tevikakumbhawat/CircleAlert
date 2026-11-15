const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Cloud Function triggered whenever a new geofence exit event document is created.
 * Dispatches targeted push notifications to all group members EXCEPT the member who exited.
 */
exports.onGeofenceExitEventCreated = functions.firestore
  .document("exitEvents/{eventId}")
  .onCreate(async (snap, context) => {
    const event = snap.data();
    if (!event) {
      console.log("No event data found in snapshot.");
      return null;
    }

    const {
      groupId,
      groupName,
      geofenceName,
      userId,
      userName,
      distanceOutsideMeters,
      isSimulated,
    } = event;

    console.log(
      `Processing exit event for user ${userName} (${userId}) in group ${groupId}`
    );

    try {
      // 1. Fetch all members in the tracking group
      const membersSnap = await db
        .collection("groups")
        .doc(groupId)
        .collection("members")
        .get();

      if (membersSnap.empty) {
        console.log(`No members found for group ${groupId}`);
        return null;
      }

      // 2. Filter out the exiting user so they do not receive their own alert
      const otherMembers = [];
      membersSnap.forEach((doc) => {
        const member = doc.data();
        if (member.userId !== userId && member.pushToken) {
          otherMembers.push(member);
        }
      });

      if (otherMembers.length === 0) {
        console.log("No other group members with valid push tokens found.");
        return null;
      }

      const registrationTokens = otherMembers.map((m) => m.pushToken);
      const prefix = isSimulated ? "[SIMULATION] " : "⚠️ ";
      const distanceText =
        distanceOutsideMeters > 0
          ? ` (${Math.round(distanceOutsideMeters)}m outside)`
          : "";

      // 3. Construct the APNs & FCM payload
      const payload = {
        notification: {
          title: `${prefix}Geofence Alert: ${userName}`,
          body: `${userName} has exited the '${geofenceName}' safe zone${distanceText}!`,
        },
        data: {
          eventId: context.params.eventId,
          groupId: groupId,
          groupName: groupName || "CircleAlert Group",
          userId: userId,
          userName: userName,
          isSimulated: String(Boolean(isSimulated)),
          click_action: "FLUTTER_NOTIFICATION_CLICK", // Standard action intent
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              "interruption-level": "critical",
            },
          },
        },
        tokens: registrationTokens,
      };

      // 4. Send multicast push notification to all other members
      const response = await admin.messaging().sendEachForMulticast(payload);
      console.log(
        `Successfully sent ${response.successCount} alerts, failed: ${response.failureCount}`
      );

      return {
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
    } catch (error) {
      console.error("Error dispatching exit notifications:", error);
      return null;
    }
  });
