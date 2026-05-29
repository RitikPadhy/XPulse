# Known Issues

## Timezone spoofing (low priority)
The quest lock/reset uses the device-reported timezone (session-pinned) with
the server clock. A user could set a **fake OS timezone** to shift their own
day window — but they gain no unearned XP (XP is proportional to real
progress). If it ever needs to be airtight, derive the timezone server-side
via **IP geolocation** instead. Not worth it now.
