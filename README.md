# Eleados_server
This is the system server for Eleados NFC Readers. It provides easy management of cards, readers, zones, and time rules for cards. 

The PostgreSQL database holds the state of the system. Any changes in the database are automatically processed and securely propagated to the appropriate recipients using MQTT. 


# Prerequisites
- Linux server with Docker
- Ability to add DNS records pointing to this server
  

# Getting started

 - Clone this repository into your desired folder: `git clone https://github.com/teasin951/Eleados_server/`.
 - Check all environmental variables in `docker-compose.yml`. Modify passwords for PostgreSQL and Mosquitto.
 - Create a DNS record for this server through which devices will reach Mosquitto. 
 - For easy setup run `scripts/first_setup.sh` which will try to lead you through the initial setup of this system (it is not very sophisticated, thus you might need to do some parts manually, especially if you have a non-standard setup).
 - Generate keys and certificates for your devices using `certs/scripts/create_device_cert.sh`. Each device should get it's own pair.
 - Insert configurations and devices into the database (and thus the system). See: TODO.
 - Connect devices and start using the system.


# Troubleshooting
TODO


# Usage
TODO




---

_Tento software vznikl za podpory Fakulty informačních technologií ČVUT v Praze, [fit.cvut.cz](https://fit.cvut.cz/)_

<img src="https://fit.cvut.cz/static/images/fit-cvut-logo-cs.svg" width="200" />
