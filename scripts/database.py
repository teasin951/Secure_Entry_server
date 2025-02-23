
#
# These are the functions that implement database calls
# if you wish to use your own database, modify them accordingly
#

# amma use SQLite3, the size of this database is small and it's the simplest
#
# It is going to be basically used as the main reference for the current setup as the mosquitto
# broker otherwise retains configuration messages and thus keeps the state even after restart,
# but digging the system state up from the mosquitto messages and ACLs is inpractical and not scalable
#
# Debezium might be great if using external database

# Create a new group in the database
def add_group_database( group_name ):
    pass

# Remove a group from the database
def remove_group_database( group_name ):
    pass

# Add a reader to a group in the database
def add_reader_to_group_database( reader, group_name ):
    pass

# Remove a reader from a group in the database
def remove_reader_from_group_database( reader, group_name ):
    pass

# Add a user to a group in the database
def add_user_to_group_database( user, group_name ):
    pass

# Remove a user from a group in the database
def remove_user_from_group_database( user, group_name ):
    pass

