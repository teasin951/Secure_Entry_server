/*
    Handle insert into time_rule

    - Do nothing, time rule has to be assigned first to have effect
*/
-- No function needed --

/*
    Handle update on time_rule

    - Do nothing, nothing important should be able to be updated, id_zone cannot be changed if it is referenced 
*/
-- No function needed --


/*
    Handle delete on time_rule

    - Do nothing
        after this the delete will cascade to time_constraints, but when they will try to select dependencies
        there won't be any, thus nothing will happen. card_time_rule delete will handle whitelist modifications
*/
-- No function needed --