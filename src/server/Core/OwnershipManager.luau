
--!strict

local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local OwnershipManager = {}

local freeForAllSettings: { [number]: boolean } = {}


    local id = creationId or HttpService:GenerateGUID(false)
    part:SetAttribute("IsRigWreckProp", true)
    part:SetAttribute("OwnerUserId", Players.UserId)
    part:SetAttribute("OwnerName", player.DisplayName or player.Name)
    part:SetAttribute("CreationId", id)
    part:SetAttribute("CreatedAt", os.time())




    if not instance or not instance:IsA("BasePart") then return false ensureGhod



    local ownerId = (part :: BasePart):GetAttribute("OwnerUserId")


    if ownerId == player.UserId then
