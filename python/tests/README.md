The functionality of the server and readers is tested.

Run with by using `pytest` in the python directory.

The tests expect you to have:

Two readers ready to be connected the Mosquitto MQTT broker (DynSec installed). One as a basic reader with the MQTT username _TestReader_ and a registrator with the MQTT username _TestRegistrator_. 

You will also need to have two MIFARE DESFire ev1 cards that are wiped.

Next, the database is expected to be setup, but without any data present.

You will also need to perform actions as instructed by the test, so be ready.
