# aggregamus
Big data with substitution plans.

## How to use
0. Make sure that you understand all of the instructions first, because you
probably want to modify them.
1. Create the configuration (`/etc/aggregamusrc.json`), it looks like this:
```json
{
    "username": "133742",
    "password": "topsecret",
    "output": "/var/dsb",
    "proxy": "127.0.0.1:5566"
}
```
2. Make sure, your output directory exists:
```sh
mkdir -p /var/dsb
```
3. Make sure, you have a Tor proxy running at the address specified in `proxy`:
```sh
sudo docker run -d -p 5566:5566 -p 4444:4444 --env tors=42 --restart always --name tor-proxy mattes/rotating-proxy
```
4. Make sure, you have Dart installed:
```sh
sudo apt install dart
```
5. Install `aggregamus`:
```sh
git clone https://github.com/Ampless/aggregamus.git
cd aggregamus
dart compile exe bin/aggregamus.dart
sudo mv bin/aggregamus.exe /usr/bin/aggregamus
```
6. Run `aggregamus`: Either through systemd, or just through the shell:
```sh
aggregamus
```
