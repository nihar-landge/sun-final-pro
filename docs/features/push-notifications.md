# Notifications (in-app only)

Push notifications (FCM/Firebase) were removed in the final architecture.
The notification surface is the in-app inbox owned by notification-service;
status-change emails ride the Express email service. See
[notifications-events.md](notifications-events.md). The FCM variant is
preserved on the `advanced` branch.
