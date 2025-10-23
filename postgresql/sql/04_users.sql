
/* For python mqtt client */
CREATE USER System WITH PASSWORD 'System_password';

/* For adding/removing cards, rules, and zones */
CREATE USER Operator WITH PASSWORD 'Operator_password';

/* For modifying configs and adding devices */
CREATE USER Administrator WITH PASSWORD 'Administrator_password';