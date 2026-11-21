return {
    FounderUserIds = {},
    AllowDirectorDelegation = false,
    StudioPersistence = false,
    AuditCapacity = 300,
    AuditRetentionDays = 30,
    MaxCashChange = 1000000,
    MaxItemQuantity = 50,
    MaxBanDays = 365,
    Permissions = {
        kick = "MODERATOR", ban = "ADMIN", unban = "ADMIN", history = "MODERATOR",
        goto = "SUPPORT", bring = "MODERATOR", freeze = "MODERATOR", unfreeze = "MODERATOR",
        spectate = "SUPPORT", heal = "MODERATOR", revive = "ADMIN", god = "ADMIN",
        announce = "ADMIN", settime = "DIRECTOR", setweather = "DIRECTOR",
        balance = "ADMIN", setmoney = "FOUNDER", givemoney = "FOUNDER", removemoney = "FOUNDER",
        inventory = "ADMIN", giveitem = "FOUNDER", removeitem = "FOUNDER",
        setteam = "DIRECTOR", role = "DIRECTOR", logs = "DIRECTOR",
    },
}
