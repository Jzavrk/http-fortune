# Http-fortune

Simple fortune delivery service.

Http server is meant to be coupled with a reverse-proxy (e.g. Nginx) through a UNIX Socket.

---

## Dependancies

 * lua-http
 * fortune-mod

## Usage

        LUA_PATH="repo/location/?.lua;;" lua server.lua
