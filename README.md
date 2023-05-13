# aggregamus

Big data with substitution plans.

## How to use

Make sure that you understand all of the instructions first, because you
probably want to modify them.

1. Create the [configuration file](aggregamusrc.example.json) at
   `/etc/aggregamusrc.json`
2. Make sure, your output directory exists: `mkdir -p /var/dsb`
3. Make sure, you have a Tor proxy running at the address specified in `proxy`:
   `sudo docker run -d -p 9050:9050 -p 9052:9052 -p 9053:9053 --restart always --name tor-proxy chrissx/tor-proxy`
4. Make sure, you have Dart installed: `apt install dart`, `pacman -S dart`, ...
5. Run `aggregamus`: Either through systemd, or just through the shell
