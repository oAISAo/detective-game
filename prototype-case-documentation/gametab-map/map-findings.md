1. Evidence polaroids
   the image has different heights based on the Evidence name. If the name is in two lines, the image is a square (1:1) which is correct. But if the test is just in one line, the image get's a bigger height and it's not the same as the width anymore. The name space should always have the height of two lines, and if the text is just one line it should be aligned to the bottom or the middle (vertically). The polaroids generally have different sizes based on if there's just one piece of evidence in a row or if there's two, and if there's a scrollbar on the left.
   EXPECTATION: The polaroid card sizes and image sizes should be consistent, but if the screen has a bigger resolution they should dynamically increase.

2. Notifications order
   Discovering `ev_mark_call_log` fires `trig_unlock_office` → Victim's Office becomes available
   Notification: "New location unlocked: Victim's Office" comes before the Notification about new evidence discovered.
   EXPECTATION: the new location unlocked notification should come after the evidence discovered notification

3. I don't like how desk Drawer just appears after the safe has been found. When the Desk Drawer unlocks, instead of just appearing silently let's implement a Brief target reveal animation:
   Drawer fades/slides into list
   Subtle highlight pulse
   THIS IS DONE, but it's not looking great yet.
