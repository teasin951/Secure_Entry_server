import asyncio
import psycopg2
from psycopg2.extras import DictCursor
from mqtt import MQTTHandler
from tasks import TaskHandler
import logging


logger = logging.getLogger(__name__)


class TaskFailedException(Exception):
    """ Custom exception class
    """
    pass


class DatabaseHandler:
    def __init__ (self, hostname, port, dbname, username, password, mqtthandler:MQTTHandler):
        """ Connect to the specified database and listen for notifications
        """

        self.timeout = 10
        self.mqtthandler = mqtthandler
        self.conn = psycopg2.connect(
            host=hostname, 
            port=port,
            dbname=dbname, 
            user=username, 
            password=password
        )
        self.conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)

        self.taskhandler = TaskHandler(self.conn, mqtthandler)
        mqtthandler.set_db_connection(self.conn)

        asyncio.run( self.process_tasks() )


    async def process_tasks(self):
        """ Poll and process tasks from the database task_queue
        """

        tasks_in_queue = 0

        while 1:
            # Just to not poll all the time, but don't wait if there are tasks in queue
            if(tasks_in_queue == 0):
                await asyncio.sleep(0.5)

            with self.conn.cursor(cursor_factory=DictCursor) as cur:
                try:
                    tasks_in_queue = self.query_task_queue(cur)

                except psycopg2.Error as e:
                    logger.error(f"Database error: {e}")
                    logger.error(f"Reattempting in {self.timeout} s")
                    await asyncio.sleep(self.timeout)

                except TaskFailedException as e:
                    logger.error(f"Task failed to be carried out, id_task = {e}")
                    logger.error(f"Retrying in {self.timeout} s")
                    await asyncio.sleep(self.timeout)


    def query_task_queue(self, cur):
        # Get the oldest task
        cur.execute("""
            SELECT count(*) OVER () AS in_queue, id_task, task_type, payload 
            FROM task_queue
            WHERE pending = FALSE
            ORDER BY created_at, id_task
            LIMIT 1;
        """)
        task = cur.fetchone()

        if not task:
            return 0

        if( not self.taskhandler.carry_out_task(task) ):
            raise TaskFailedException(task['id_task'])

        return task['in_queue']

