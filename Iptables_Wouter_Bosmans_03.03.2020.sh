# (C) 2020 Wouter Bosmans - r0737827

# This script is IPv4 only.

# The server is provided with the following services: Apache, ProFTPd and bind9.
# Please, do not allow zonetransfers. Also protect the server against ping flooding.
# The server is not allowed to make outgoing connections, except for the installation of security updates.



# APACHE WEBSERVER
sudo iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

# PROFTPD FTP SERVER
# a) Control connections on port 21
sudo iptables -A INPUT  -p tcp -m tcp --dport 21 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -p tcp -m tcp --sport 21 -m conntrack --ctstate ESTABLISHED -j ACCEPT
# b) Active FTP mode - Allow data connections initiated by server from port 21
sudo iptables -A OUTPUT -p tcp -m tcp --sport 20 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A INPUT  -p tcp -m tcp --dport 20 -m conntrack --ctstate ESTABLISHED -j ACCEPT -m comment
# c) Passive FTP mode - Allow data connections initiated by client on unprivileged ports
sudo iptables -A INPUT -p tcp -m tcp --sport 1024: --dport 1024: -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -p tcp -m tcp --sport 1024: --dport 1024: -m conntrack --ctstate ESTABLISHED -j ACCEPT
sudo modprobe nf_conntrack_ftp

# BIND9 DNS SERVER
# Zone transers over TCP 53, DNS queries over UDP 53
sudo iptables -I INPUT 2 -p udp -m udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -p udp -m udp --sport 53:65535 --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT

# ICMP PING FLOODING PROTECTION
sudo iptables -t filter -A INPUT -p icmp --icmp-type echo-request -m limit --limit 5/minute -j ACCEPT
sudo iptables -t filter -A INPUT -p icmp -j DROP
sudo iptables -t filter -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT

# SETUP DEFAULT POLICY RULES
sudo iptables -P INPUT DROP
sudo iptables -P OUTPUT DROP
sudo iptables -P FORWARD DROP

# SAVE AND APPLY CONFIGURATION
sudo service iptables save
sudo service iptables restart