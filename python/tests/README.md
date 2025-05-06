The functionality of the server and readers is tested.

Run with by using `pytest` in the python directory.

The tests expect you to have:

Two readers ready to be connected the Mosquitto MQTT broker (DynSec installed). One as a basic reader with the MQTT username _TestReader_ and a registrator with the MQTT username _TestRegistrator_. 

You will also need to have two wiped MIFARE DESFire ev1 cards.

The database is expected to be deployed but without any data present.

The python script should be up and running.

The reader tests are interactive. You will need to perform actions as instructed by the tests, so be ready.

If some tests fail, it can lead to other tests failing. In that case use `pytest -k <specify test>` to rerun only specific tests.
