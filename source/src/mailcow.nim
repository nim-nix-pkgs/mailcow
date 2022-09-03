import httpclient, uri, json, strformat

##API DOCS: https://mailcow.docs.apiary.io/

type
  Session* = ref object
    url*: Uri
    apikey*: string
    client*: HttpClient

proc setInfo*(domain: string, key: string): Session =
  ##Sets the URL and the API key  
  var client = newHttpClient()
  client.headers = newHttpHeaders({
    "Content-Type": "application/json",
    "X-API-Key": key
  })

  return Session(url: domain.parseUri, apikey: key, client:client)

proc getDomains*(self: Session, domain: string = "all"): JsonNode =
  ##Return Domain settings, by default it returns all domains
  let resp = self.client.getContent($(self.url / "api/v1/get/domain/" / domain))
  return parseJson(resp)

proc createDomain*(self: Session, domain: string, description: string = "",
                  aliases: int = 400, mailboxes: int = 10, defquota: int = 3072,
                  maxquota: int = 10240, quota: int = 10240, active: int = 1,
                  rl_value: int = 10, rl_frame: string = "s", backupmx: int = 0,
                  relay_all_recipients: int = 0, restart_sogo: int = 0): JsonNode =
  ##Creates a Domain. Defaults values are from Mailcow
                
  let data = %*{
              "domain": domain,
              "description": description,
              "aliases": aliases,
              "mailboxes": mailboxes,
              "defquota": defquota,
              "maxquota": maxquota,
              "quota": quota,
              "active": active,
              "rl_value": rl_value,
              "rl_frame": rl_frame,
              "backupmx": backupmx,
              "relay_all_recipients": relay_all_recipients,
              "restart_sogo": relay_all_recipients
            }
  
  var resp = self.client.request($(self.url / "api/v1/add/domain"),
                                  httpMethod = HttpPost, body = $data)
  return parseJson(resp.body)

proc updateDomain*(self: Session, domain: string, description: string="",
                  aliases: string = "", mailboxes: string = "", defquota: string = "",
                  maxquota: string = "", quota: string = "", active: string = "",
                  backupmx: string = "", relay_all_recipients: string = "",
                  gal: string = "", relayhost: string = ""): JsonNode =
  ##Updates a Domain and only changes the called parameters

  let data = %*{
              "items": [
                domain
              ],
              "attr": {
                "description": description,
                "aliases": aliases,
                "mailboxes": mailboxes,
                "defquota": defquota,
                "maxquota": maxquota,
                "quota": quota,
                "active": active,
                "gal": gal,
                "relayhost": relayhost,
                "backupmx": backupmx,
                "relay_all_recipients": relay_all_recipients
              }
            }

  let resp = self.client.request($(self.url / "api/v1/edit/domain"), 
                                  httpMethod = HttpPost, body = $data)
  return parseJson(resp.body)

proc deleteDomain*(self:Session, domain: string): JsonNode =
  ##Deletes the provided domain
  let data = fmt"""["{domain}"]"""
  let resp = self.client.request($(self.url / "api/v1/delete/domain"), 
                                  httpMethod = HttpPost, body = data)
  return parseJson(resp.body)

proc getDomainWhitelist*(self: Session, domain: string): JsonNode =
  ##Adds a Domain to a whitelist
  let resp = self.client.getContent($(self.url / "api/v1/get/policy_wl_domain" / domain))
  return parseJson(resp)

proc getDomainBlacklist*(self: Session, domain: string): JsonNode =
  ##Adds a Domain to a blacklist
  let resp = self.client.getContent($(self.url / "api/v1/get/policy_bl_domain" / domain))
  return parseJson(resp)

proc createDomainPolicy*(self: Session, domain: string, wl_bl: string, 
                        toblock: string): JsonNode =
  ##Creates a Domain policy
  let data = %*{
              "domain": domain,
              "object_list": wl_bl,
              "object_from": toblock
            }
  let resp = self.client.request($(self.url / "api/v1/add/domain-policy"), 
                                  httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)
  
proc deleteDomainPolicy*(self: Session, domain: string): JsonNode =
  ##Deletes a Domain policy
  let data = fmt"""["{domain}"]"""

  let resp = self.client.request($(self.url / "api/v1/delete/domain-policy"), 
                                  httpMethod = HttpPost, body = data)
                              
  return parseJson(resp.body)

proc getMailboxes*(self: Session, id: string): JsonNode =
  ##Returns the Mailbox from the provided ID
  let resp = self.client.getContent($(self.url / "api/v1/get/mailbox" / id))
  return parseJson(resp)

proc createMailbox*(self: Session, local_part: string, domain: string, name: string,
                    quota: string = "3072", password: string, active: bool = true,
                    force_pw_update: bool = false, tls_enforce_in: bool = false,
                    tls_enforce_out: bool = false): JsonNode =
  
  ##Creates a Mailbox and uses some of the Mailcow default Values
  let data = %*{
                "local_part": local_part,
                "domain": domain,
                "name": name,
                "quota": quota,
                "password": password,
                "password2": password,
                "active": active.int,
                "force_pw_update": force_pw_update.int,
                "tls_enforce_in": tls_enforce_in.int,
                "tls_enforce_out": tls_enforce_out.int,
                }

  let resp = self.client.request($(self.url / "api/v1/add/mailbox"), httpMethod = HttpPost,
                                body = $data)
    
  return parseJson(resp.body)

proc updateMailbox*(self: Session, mailbox: string, name: string = "",
                    quota: string = "", password: string = "", active: string = "",
                    force_pw_update: string = "", sogo: string = ""): JsonNode =
  ##Updates a Mailbox and only changes the called parameters
  let data = %*{
                "items": [
                  mailbox
                ],
                "attr": {
                   "attr": {
                    "name": name,
                    "quota": quota,
                    "password": password,
                    "password2": password,
                    "active": active,  
                    "force_pw_update": force_pw_update,
                    "sogo_access": sogo
                    }
                  }
              }

  let resp = self.client.request($(self.url / "api/v1/edit/mailbox"),
                                 httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

proc updateSpamScore*(self: Session, mailbox: string, score: string): JsonNode =
  ##Updates the Spamscore for the
  ##Mailbox has to be the full E-Mail address (example@example.com)
  let data = %*[
                {
                  "items": [
                    mailbox
                  ],
                  "attr": {
                    "spam_score": score
                  }
                }
              ]

  let resp = self.client.request($(self.url / "api/v1/edit/spam-score"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

proc deleteMailbox*(self: Session, mailbox: string): JsonNode =
  ##Deletes the provided Mailbox
  let data = %*[
                mailbox
               ]

  let resp = self.client.request($(self.url / "api/v1/delete/mailbox"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)  

proc setQuarantineNoti*(self: Session, mailbox: string, time: string): JsonNode =
  ##Sets the Quarantine Notifications Settings.
  ##Valid time settings are: hourly, daily, weekly, never
  let data = %*{
                "items": [
                  mailbox
                ],
                "attr": {
                  "quarantine_notification": time
                }
              }

  let resp = self.client.request($(self.url / "api/v1/edit/quarantine_notification"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

proc getAliases*(self: Session, id: string): JsonNode =
  ##Return the Alias settings
  ##Valid id values are: all or the number
  let resp = self.client.getContent($(self.url / "api/v1/get/alias" / id))

  return parseJson(resp)

proc createAlias*(self: Session, mailbox: string, goto: string, active: string): JsonNode =
  ##Creates an alias
  let data = %*{
                "address": mailbox,
                "goto": goto,
                "active": active
              }

  let resp = self.client.request($(self.url / "api/v1/add/alias"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

proc updateAlias*(self: Session, id: string, address: string = "", goto: string = "",
                  priv: string = "", pub: string = "", active: string = ""): JsonNode =
  ##Updates the alias settings
  let data = %*{
                "items": [
                  id
                ],
                "attr": {
                  "address": address,
                  "goto": goto,
                  "private_comment": priv,
                  "public_comment": pub,
                  "active": active
                }
              }

  let resp = self.client.request($(self.url / "api/v1/edit/alias"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

proc deleteAlias*(self: Session, id: string): JsonNode =
  ##Deletes an Alias
  let data = %*[
                id
              ]

  let resp = self.client.request($(self.url / "api/v1/delete/alias"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

proc getLogs*(self: Session, service: string, count: string): JsonNode =
  ##Valid Services are: postfix, rspamd-history, dovecot, acme, sogo, watchdog, api, ratelimited, netfilter, autodiscover
  let resp = self.client.getContent($(self.url / "api/v1/get/logs" / service / count))

  return parseJson(resp)

proc getQueue*(self: Session): JsonNode =
  ##Returns the current Queue as a JsonNode
  let resp = self.client.getContent($(self.url / "api/v1/get/mailq/all"))

  return parseJson(resp)

proc flushQueue*(self: Session): JsonNode =
  ##Flushes the Queue
  let data = %*{
                "action": "flush"
              }

  let resp = self.client.request($(self.url / "api/v1/edit/mailq"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

proc deleteQueue*(self: Session): JsonNode =
  ##Deletes the current Queue
  let data = %*{
                "action": "super_delete"
              }

  let resp = self.client.request($(self.url / "api/v1/delete/mailq"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

proc getQuarantine*(self: Session): JsonNode =
  ##Returns all Mails in the Quarantine as a JsonNode 
  let resp = self.client.getContent($(self.url / "api/v1/get/quarantine/all"))

  return parseJson(resp)

proc deleteQuarantine*(self: Session, id: string): JsonNode =
  ##Deletes a Mail from the Quarantine
  let data = %*[
                id
              ]

  let resp = self.client.request($(self.url / "api/v1/delete/qitem"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

proc getFail2Ban*(self: Session): JsonNode =
  ##Gets the current Fail2Ban settings
  let resp = self.client.getContent($(self.url / "api/v1/get/fail2ban"))

  return parseJson(resp)

proc editFail2Ban*(self: Session, ban_time: string ="", max_attempts: string ="",
                  retry_window: string ="", netban_ipv4: string = "",
                  netban_ipv6: string ="", whitelist: string = "",
                  blacklist: string =""): JsonNode =
  ##Edits the Fail2Ban settings
  ##Only edits the called parameters
  let data = %*{
                "items": [
                  "none"
                ],
                "attr": {
                  "ban_time": ban_time,
                  "max_attempts": max_attempts,
                  "retry_window": retry_window,
                  "netban_ipv4": netban_ipv4,
                  "netban_ipv6": netban_ipv6,
                  "whitelist": whitelist,
                  "blacklist": blacklist
                }
              }

  let resp = self.client.request($(self.url / "api/v1/edit/fail2ban"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

proc getDkim*(self: Session, domain: string): JsonNode =
  ##Gets the public DKIM key for the provided Domain
  let resp = self.client.getContent($(self.url / "api/v1/get/dkim" / domain))

  return parseJson(resp)

proc generateDkim*(self: Session, domain: string, size: string = "2048"): JsonNode =
  ##Generates a DKIM key for the provided domain
  ##Default size is 2048
  let data = %*{
                "domains": domain,
                "dkim_selector": "dkim",
                "key_size": size
              }

  let resp = self.client.request($(self.url / "api/v1/add/dkim"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

proc duplicateDkim*(self: Session, from_domain: string, to: string): JsonNode =
  ##Duplicates the DKIM key from one domain to another
  let data = %*{
                "from_domain": from_domain,
                "to_domain": to
              }

  let resp = self.client.request($(self.url / "api/v1/add/dkim_duplicate"),
                                httpMethod = HttpPost, body = $data)

  return parseJson(resp.body)

