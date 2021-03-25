# aggregamus
Big data with substitution plans.

## How to use
Make sure that you understand all of the instructions first, because you
probably want to modify them.

1. Create the [configuration file](aggregamusrc.example.json) at
`/etc/aggregamusrc.json`
2. Make sure, your output directory exists: `mkdir -p /var/dsb`
3. Make sure, you have a Tor proxy running at the address specified in `proxy`:
`sudo docker run -d -p 5566:5566 -p 4444:4444 --env tors=42 --restart always --name tor-proxy mattes/rotating-proxy`
4. Make sure, you have Dart installed: `sudo apt install dart`
5. Download `aggregamus`:
`git clone https://github.com/Ampless/aggregamus.git && cd aggregamus && dart pub get`
6. Install `aggregamus`:
`dart compile exe bin/aggregamus.dart && sudo mv bin/aggregamus.exe /usr/bin/aggregamus`
7. Run `aggregamus`: Either through systemd, or just through the shell:
`aggregamus`
