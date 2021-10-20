+++
title = "Wildcard Certificates in Caddy Server"
date = "2021-10-20"
author = "derek"
draft = false
cover = ""
tags = ["caddy", "self-hosted", "open-source", "reverse-proxy"]
keywords = ["", ""]
description = "Caddy Server is a simple and versatile web server with automatic SSL certificate generation using Let's Encrypt (or ZeroSSL). By default it will generate a new certificate for each subdomain, but sometimes you just want to use a wildcard."
showFullContent = false
+++

#### !! Disclaimer !!

While there are undoubtably benefits to using a wildcard certificate they should be used with caution. By their very nature they allow for any subdomain under the root domain to use it. While they make it easy to add new services quickly in a homelab environment they should generally be avoided for public facing systems. The NSA actually has a write up with more details here: [https://www.nsa.gov/Press-Room/News-Highlights/Article/Article/2804293/avoid-dangers-of-wildcard-tls-certificates-the-alpaca-technique/](https://www.nsa.gov/Press-Room/News-Highlights/Article/Article/2804293/avoid-dangers-of-wildcard-tls-certificates-the-alpaca-technique/)

---

## Caddy and the Caddyfile

There are a lot of web servers you can choose to use. When looking at reverse proxy or load balancing solutions common names are Nginx, Apache, Traefik, and Caddy. After trying all of them I settled on Caddy for some of my needs due to the simplicity of configuration. Caddy Server is a single binary server written in Go and uses a single configuration file named `Caddyfile` to define the routes and other details needed by the server. It can be so simple in fact that this is all you need to define in the file to setup a reverse proxy to a different server.

```yaml
service.example.com
reverse_proxy 10.0.0.11:8080
```

This will automatically generate a valid SSL certificate for `service.example.com` using Let's Encrypt and then forward all requests and headers to `10.0.0.11:8080`. This makes adding new service configurations extremely quick and relatively hassle-free. You can also define the email to use for the renewal notifications on the domains by setting a block with the email directive at the top of the file. 

```yaml
{
	email email@example.com
}

service.example.com {
	reverse_proxy 10.0.0.11:8080
}

service2.example.com {
	reverse_proxy 10.0.0.12
}
```

This works well, but does require a new certificate to be generated for each service. There are times where a wildcard certificate is desired. In the Caddyfile this is defined by setting the domain to `*.example.com, example.com`. By default Caddy will use the Let's Encrypt HTTP-01 challenge type which requires port 80 to be open up to your server. Unfortunately, this is not a supported challenge type for wildcard certificates. To generate a wildcard certificate you will need to use the DNS-01 challenge type which requires using a [supported DNS provider](https://community.letsencrypt.org/t/dns-providers-who-easily-integrate-with-lets-encrypt-dns-validation/86438). This is defined with a `tls { }` block added below your domain definition. In the block you define the parameters required for your DNS provider which will be documented in their individual module notes. After this the Caddyfile should look similar to this.

```yaml
{
	email email@example.com
}

*.example.com, example.com {
	tls {
		dns cloudflare {env.CLOUDFLARE_API_TOKEN}
	}
}
```

*Note: by default Caddy Server does not contain any DNS modules. These need to be added to your download from [caddyserver.com](https://caddyserver.com) or built manually using the xcaddy tool. [https://caddy.community/t/how-to-use-dns-provider-modules-in-caddy-2/8148](https://caddy.community/t/how-to-use-dns-provider-modules-in-caddy-2/8148)*

After defining the domain block you need to define the individual services beneath. Because they are all nested you will need to use the Caddy matcher directives so that services can be properly routed. That line will look like `@service host service.example.com`. This will catch any request with service.example.com in the Host header will be set to the @service tag. Next you need to handle the tag and actually define the routing, this is defined with `handle @service { < routing definitions > }`. When you put all this together you should get something like the following Caddyfile.

```yaml
{
	# Optional: set root folder for Caddyfile and Certificates
	storage file_system {
		root /etc/caddy
	}
	email email@example.com
}

*.example.com, example.com {
	tls {
		dns cloudflare {env.CLOUDFLARE_API_TOKEN}
	}

	# Standard reverse proxy
	@nextcloud host nc.example.com
	handle @nextcloud {
		reverse_proxy 10.0.0.11
	}

	# Reverse proxy to unsecure HTTPS backend
	@proxmox host proxmox.example.com
	handle @proxmox {
		reverse_proxy https://10.0.0.10:8006 {
			transport http {
				tls
				tls_insecure_skip_verify
			}
		}
	}

	# Reverse proxy to different container on same Docker network
	@home host home.example.com
	handle @home {
		reverse_proxy homer:8080
	}
}
```

You should now be able to start up the Caddy Server and, after the certificates are generated, access your services using a wildcard certificate.

## Reloading the Caddyfile

If you are running Caddy inside of a Docker container and don't want to stop and restart your container in order to reload the config you can take the follow snippet and put it into a file. When you execute the file it will get the ID for the container running Caddy, and send the reload command to the container. You may need to update the internal path to the Caddyfile.

```bash
#!/usr/bin/bash

caddy_container_id=$(docker ps | grep caddy | awk '{print $1;}')
docker exec $caddy_container_id caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
```



