name "Emergency Siren Control"
author "glitchdetector, xLaugh"
version "1.2"
download "https://github.com/xLaugh/fivem-emergency-siren-control"

details [[
    Originally created for Transport Tycoon by glitchdetector
    Entity enumerator by IllidanS4
    Standalone-ized for release on the CitizenFX Forums
    Fixed siren synchronization between clients
]]

usage [[
    Any vehicle with emergency lights will be silent by default
    You can press the Cinematic Camera button while lights are enabled to toggle the siren
    Siren does not sound if no-one is in the driver seat of the vehicle
    Sirens are now properly synchronized between all clients
]]

description "A custom siren control system with proper multiplayer synchronization"

fx_version 'cerulean'
game 'gta5'

dependencies {'instructional-buttons'}
client_script '@instructional-buttons/include.lua'

client_script 'dep/enumerator.lua'
client_script 'cl_esc.lua'
server_script 'sv_esc.lua'
