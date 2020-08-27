+++
title = "Using LibreSwan with Azure VPN Gateway"
date = "2020-08-26T16:13:19-05:00"
author = "derek"
draft = false
cover = ""
tags = ["azure", "vpn", "libreswan"]
keywords = ["", ""]
description = "Connecting a local network to Azure is a lot more complex than it should be without a hardware VPN. This guide should hopefully help ease some of that complexity."
showFullContent = false
+++

I recently found myself in a position where I needed to connect a portion of a local network to an Azure virtual network. While a hardware VPN device would have been the best option I did not have one available to me, so I went with a software solution using LibreSwan to create the tunnel. Before I get into the configuration of LibreSwan I want to mention that this will not be as performant as a hardware VPN appliance. If you need the utmost in performance then you should look at those.

# Prerequisites

You will need an Azure VPN Gateway. While I could go through the setup of a VPN Gateway in Azure there is already a fantastic guide in the Azure Docs that will walk you through creating all the required Azure components >[here](https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-site-to-site-resource-manager-portal)<. Take note of the Public IP for the Gateway as well as the shared key you specified while creating the Connection resource.

I used CentOS 7.8 for the deployment. While the general steps will remain the same, the exact commands may be altered slightly depending on the OS you are using. In most cases the system does not require a lot of processing power; I used a VM with 2 CPUs and 2GB RAM. While fewer resources may work I have not tested with less than that.

You will need a static public IP for your local network that can be assigned to your local gateway. If behind a NAT then you will want to forward ports `500/udp` and `4500/udp+tcp` to the gateway machine.

You should apply a route to your local router to forward all local traffic headed to the Azure address space to be redirected to the local IP of the LibreSwan (local) gateway. It is possible to specify the forwarding on the local client, but this can become tedious and is best used for testing only. The command is `route -p ADD <azure subnet> MASK 255.255.255.0 <local gateway private ip> METRIC 100` if you need it.

# Installation and Configuration

Once you have all the prerequisites in place and have installed the base OS for the local gateway make sure that you have updated it with the latest packages and then install LibreSwan.

```bash
yum update -y && yum install libreswan
```

To prepare the network adapter and the system to act as a tunnel endpoint we need to update some parameters. First, update `/etc/sysctl.conf` to include the following:

```bash
net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
```

Then update any VPN adapter configurations by running the following script

```bash
for vpn in /proc/sys/net/ipv4/conf/*; do
    echo 0 > $vpn/accept_redirects;
    echo 0 > $vpn/send_redirects;
done
```

After these are done, apply the changes with 

```bash
sysctl -p
```

Next we need to apply the firewall and iptables rules to forward any traffic going to or coming from the VPN tunnel to the proper destination. 

For the firewall the following rules should work. Make sure to update the local subnet and the name of the network adapter you are using. In the example below my network adapter is `eth0` and my local address space is `192.168.1.0/24`

```bash
firewall-cmd --zone=public --add-port=500/udp --permanent
firewall-cmd --zone=public --add-port=4500/tcp --permanent
firewall-cmd --zone=public --add-port=4500/udp --permanent
firewall-cmd --permanent --direct --passthrough ipv4 -t nat -I POSTROUTING -o eth0 -j MASQUERADE -s 192.168.1.0/24
```

There are a number of rules to add to iptables. As above make sure to update the name of the network adapter to match your system. In the example below `10.95.1.0/24` is the address space for my Azure virtual network (make sure this is the address space for the entire vnet and not only the default subnet), `123.45.67.89` is the public IP for my Azure VPN Gateway, and as above `192.168.1.0/24` is my local address space.

```bash
iptables -A FORWARD -s 10.95.1.0/24 -m policy --dir in --pol ipsec -j ACCEPT
iptables -A FORWARD -s 192.168.1.0/24 -m policy --dir out --pol ipsec -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 500 -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 4500 -j ACCEPT
iptables -A INPUT -m policy --dir in --pol ipsec -j ACCEPT
iptables -A INPUT -p esp -j ACCEPT
iptables -t nat -A PREROUTING -i eth0 -p udp -m udp --dport 4500 -j DNAT --to-destination 123.45.67.89:4500
iptables -t nat -A PREROUTING -i eth0 -p udp -m udp --dport 500 -j DNAT --to-destination 123.45.67.89:500
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

The main configuration file for LibreSwan is found at `/etc/ipsec.conf`. Update it using the example below. Again, `192.168.1.0/24` is the local address space, `10.95.1.0/24` is the Azure address space, and `123.45.67.89` is the Azure VPN Gateway public IP. `98.76.54.32` is the local static IP for the LibreSwan gateway.

```bash
version 2.0

config setup
        logfile=/var/log/pluto.log
        plutodebug=none
        nat_traversal=yes
        virtual_private=%4:192.168.1.0/24 #<- local address space
        protostack=netkey
        interfaces=%defaultroute

conn azure
        authby=secret
        auto=start
        dpdaction=restart
        ike=aes256-sha1;dh2,3des-sha1;dh2,aes256-sha256;dh2
        ikelifetime=28800s
        ikev2=no
        encapsulation=yes
        left=%defaultroute
        leftid=98.76.54.32 #<- Local static IP
        leftnexthop=%defaultroute
        leftsubnets={192.168.1.0/24} #<- local address space
        mtu=1350
        pfs=no
        phase2alg=aes_gcm256-null,aes256-sha1,3des-sha1,aes256-sha256
        right=123.45.67.89 #<- Azure VPN Gateway public IP
        rightid=123.45.67.89 #<- Azure VPN Gateway public IP
        rightnexthop=%defaultroute
        rightsubnets={10.95.1.0/24} #<- Azure vnet address space
        salifetime=27000s
        type=tunnel
```

If needed, additional subnets can be added on either side of the tunnel by adding then to the `leftsubnets` or `rightsubnets` parameter. They should be added as comma separated values, i.e. `rightsubnets={10.95.1.0/24,10.95.2.0/24}` (if adding additional subnets make sure to add the required iptables rules). You can find a detailed description of what each key in the configuration is doing in the LibreSwan documentation >[here](https://libreswan.org/man/ipsec.conf.5.html)<.

The final file that needs to be edited is `/etc/ipsec.secrets` which is where you specify the preshared key specified during the creation of the Connection resource in Azure. Azure requires this key to be at least 16 characters long, so you may need to update the key in the Azure Connection Resource if you did not already specify one of sufficient length. The secrets file contains the local public IP, the Azure VPN Gateway public IP, and the Preshared Key, in that order.

```bash
98.76.54.32 123.45.67.89 : PSK "s3cur3p4ssw0rd!!"
```

After all of this the gateway should be ready to go. Start the service and enable it so that it starts automatically on boot.

```bash
systemctl start ipsec
systemctl enable ipsec
```

If everything is correct the VPN tunnel should now be active and functional. After a few minutes the Azure portal should report "*Connected*" as the status on the Connection resource. 

**Congratulation!** you should now have a functional site-to-site VPN tunnel using LibreSwan and an Azure VPN Gateway.

# Troubleshooting

If you are experiencing connectivity issues you can attempt opening rules wider on the local gateway to check for any local configuration errors.

To verify your `ipsec.conf` is valid and there no erroneous errors you can use the following command.

```bash
/usr/libexec/ipsec/addconn --config /etc/ipsec.conf --checkconfig
```

If traffic seems to be flowing, but is being stopped somewhere you can attempt to open the iptables rules to help isolate any flow restrictions further down the stream as follows. 

```bash
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
```

If you are behind a NAT then the firewall may be missing rules, or generally misbehaving. To check you can stop/disable the local firewall.

```bash
systemctl stop firewalld
systemctl disable firewalld
```

For more information or help troubleshooting both the LibreSwan and Azure documentation/forums are great places to look.
