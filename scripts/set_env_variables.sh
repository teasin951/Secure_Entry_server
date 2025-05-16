#!/bin/bash

#
# This script serves as a manual way of creating necessary environmental variables for testing
#
# NEEDS TO BE SOURCED TO HAVE AFFECT ON THE PARENT SHELL!


# Get script folder
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


# Get variables from user
read -re -p "Mosquitto hostname: " MOSQUITTO_HOSTNAME 
read -re -i "8883" -p "Mosquitto port: " MOSQUITTO_PORT 
read -re -i "admin" -p "DynSec admin username: " MOSQUITTO_DYNSEC_USERNAME 
read -re -i "admin" -p "DynSec admin password: " MOSQUITTO_DYNSEC_PASSWORD
read -re -i "$SCRIPT_DIR/../mosquitto/certs/ca.crt" -p "Mosquitto CA file path: " MOSQUITTO_CA_FILE_PATH

read -re -i "Server" -p "Server MQTT client username: " SERVER_MQTT_USERNAME 
read -re -i "admin" -p "Server MQTT client password: " SERVER_MQTT_PASSWORD
read -re -i "$SCRIPT_DIR/../mosquitto/certs/server.crt" -p "Mosquitto server certificate file path: " SERVER_CERT_FILE_PATH
read -re -i "$SCRIPT_DIR/../mosquitto/certs/server.key" -p "Mosquitto server key file path: " SERVER_KEY_FILE_PATH

read -re -i "localhost" -p "Database hostname: " DATABASE_HOSTNAME
read -re -i "5432" -p "Database port: " DATABASE_PORT
read -re -i "test" -p "Database name: " DATABASE_NAME
read -re -i "admin" -p "Database username: " DATABASE_USERNAME
read -re -i "admin" -p "Database password: " DATABASE_PASSWORD


# Set environmental variables
export MOSQUITTO_HOSTNAME
export MOSQUITTO_PORT
export MOSQUITTO_DYNSEC_USERNAME
export MOSQUITTO_DYNSEC_PASSWORD
export MOSQUITTO_CA_FILE_PATH

export SERVER_MQTT_USERNAME 
export SERVER_MQTT_PASSWORD 
export SERVER_CERT_FILE_PATH
export SERVER_KEY_FILE_PATH

export DATABASE_HOSTNAME
export DATABASE_PORT
export DATABASE_NAME
export DATABASE_USERNAME
export DATABASE_PASSWORD