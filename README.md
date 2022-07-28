# nextcloud-spreed-signaling_mon
A bash script that parses StrukturAg signalling server journalctl logs.

I made this script for simple system admin purposes of following a 30 users NextCloud Talk deployment with StrukturAg's signalling server. 

What does it do:
- First parses and collects data from "BACKLOG_LINES" number of lines. You should wait until parsing finishes.
- Collect information using sed lines from relevant log lines.
- Create a dynamic lookup table that follows new and finalized connections. 
- Has an internal switch --extended for displaying additional browser and geolocation info.
- You may fiddle with BACKLOG_LINES and LOOP_COUNTER variables for your convenience.
- If your log file happens to be newly rotated, 8000 (my default) lines of BACKLOG might not exist, in this case, it will sall until 8000 lines reached. In this case, you may decrease the number.
- Do not forget to change SYSTEMD_SERVICE variable according your own service filenames.

PS: I am not a software guru, and I may not have time to revise code regularly. Well, anyway I hope this small script help someone out there or provoke better ideas.

All the best.. :)
