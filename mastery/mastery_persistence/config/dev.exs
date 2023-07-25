import Config

config :mastery_persistence, MasteryPersistence.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "mastery_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
