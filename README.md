# CloudProxy

## Overview

CloudProxy serves as a very simple reverse proxy, listening on port 80 (http). It is forwarding incoming requests to either Tomcat, CouchDB, or other internal services.

Some use-cases:

 * Access services running on Amazon EC2 from applications running on Google AppEngine. Requests from AppEngine are restricted to port 80.
 * Single and "managed" entry point to services running on EC2 or any other IaaS.

CloudProxy is written in Erlang based on [webmachine] (https://github.com/basho/webmachine) and [ibrowse](https://github.com/cmullaparthi/ibrowse/).
Influenced by a [example code](https://bitbucket.org/bryan/wmexamples/) for webmachine from Bryan Fink. 


## Quick Start

CloudProxy was developed and tested using Erlang R14B03.

**Build:**

```
git clone git://github.com/neuhausler/CloudProxy.git
cd CloudProxy
make
```

**Configure:**

CloudProxy by default is listening on port 8050. Configuration for Port, internal and external URL can be modified in dispatch.conf and cloudproxy.conf.

To change port from 8050 to 80:

Edit `./priv/dispatch.conf`

```
%% Reverse Proxy CouchDB Requests
{["proxy", "couch",'*'], cloudproxy_proxy_couchdb_resource, {"http://localhost/proxy/couch/", "http://localhost:5984/"}}.

%% Reverse Proxy Tomcat Requests
{["proxy", "tomcat",'*'], cloudproxy_proxy_tomcat_resource, {"http://localhost/proxy/tomcat/", "http://localhost:8080/"}}.
```


Edit `./priv/cloudproxy.conf`

```
{port, 80}.
```

A server can be configured to track 404 "attacks" (work in progress)

Edit `./priv/cloudproxy.conf`

```
{log_attack,      true}.                                  %% Enable 404 attacks to get forwarded to the AttackGateway
{attack_gateway, "http://localhost:8080/URLForGateway"}.  %% Gateway to log 404 attacks
```


**Run:**

```
./start.sh
```

Access to CouchDB: http://localhost/proxy/couch/

Access to Tomcat:  http://localhost/proxy/tomcat/



