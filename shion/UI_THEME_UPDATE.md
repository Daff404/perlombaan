# SHION REST update

Primary actions now use a leaf-green gradient, high-contrast text and a separate arrow capsule. The forest palette, custom PNG illustrations, camera controls and bottom navigation remain in the UI.

Account and activity data now come from the authenticated REST API. `ApiStore` only holds a temporary RAM snapshot. The only persisted client value is the encrypted opaque session token on Android; web sessions stay in memory. No SharedPreferences or browser localStorage database is used.

See `README.md` and the backend README for deployment and admin setup. Leaderboard and notifications read real server data.
