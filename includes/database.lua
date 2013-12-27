dbh = {} -- Database handlers

local DBI, db_id = require 'DBI', 'default'

function db_set_db_id(id)
  db_id = id
end

function db_connect()
  local err
  local connection = settings.db[db_id]

  if connection == nil then return end

  if not connection.autocommit then connection.autocommit = true end

  dbh[db_id], err = DBI.Connect(
    connection.driver,
    connection.database,
    connection.username,
    connection.password,
    connection.host,
    connection.port
  )

  if err then
    return nil, err
  end

  -- commit the transaction
  dbh[db_id]:autocommit(connection.autocommit)

  -- check status of the connection
  return dbh[db_id]:ping()
end

function db_query(query, ...)
  if dbh[db_id] == nil then
    return nil, 'No database connection'
  end

  -- prepare a query
  local sth = assert(dbh[db_id]:prepare(query))

  -- execute select with a bind variable
  local success, err = sth:execute(...)

  return sth, err
end

function db_last_insert_id()
  local sth, err, row

  sth, err = db_query('SELECT last_insert_rowid()')
  if err then
    return nil, err
  else
    row = sth:fetch()
    return row[1]
  end
end
