#!/usr/bin/env tarantool

local set = require "set"

set.config{
  memtx_dir = "files",
  vinyl_dir = "files",
  wal_dir = "logs"
}

set.server{
  host = "127.0.0.1",
  port = 8080,
  modules = {
    "example"
  }
}