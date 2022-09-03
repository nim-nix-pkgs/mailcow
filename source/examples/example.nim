import mailcow
import json

let s = mailcow.setInfo("https://example.com", "API-KEY") #sets the domain and the API key
echo s.createDomain("example.com", aliases=5, restart_sogo=1) #creates a new domain and restarts SoGo
echo s.updateDomain("example.com", quota="20000") #changes the domain quota
echo s.createMailbox("test", "example.com", "username", password="securePassw0rd!") #creates a new mailbox
echo s.getMailboxes("test@example.com") #gets infos for the new mailbox
echo s.deleteMailbox("test@example.com") #deletes the mailbox
echo s.deleteDomain("example.com") #deletes the domain