import { readFileSync, readdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const runtime = process.argv[2];
const { LuauState } = await import(runtime ? pathToFileURL(resolve(runtime)).href : 'luau-web');
const state = await LuauState.createAsync();

try {
    const files = readdirSync(new URL('../src/', import.meta.url), { recursive: true })
        .filter(file => file.endsWith('.luau'));
    for (const file of files) {
        const source = readFileSync(new URL('../src/' + file, import.meta.url), 'utf8');
        state.loadstring(source, file, true);
    }
    console.log('Sintaxe Luau validada em', files.length, 'arquivos.');

    const modules = {
        Items: 'shared/Items.luau',
        AvatarConfig: 'shared/AvatarConfig.luau',
        Appearance: 'shared/Appearance.luau',
        Settings: 'server/Settings.luau',
        Careers: 'server/Services/Careers.luau',
        InventoryRules: 'server/Services/InventoryRules.luau',
        Economy: 'server/Services/Economy.luau',
        ProfileSchema: 'server/Services/ProfileSchema.luau',
        Inventory: 'server/Services/Inventory.luau',
    };
    const prelude = `
        local modules = {}
        local active = {}
        local function require(name) return assert(modules[name], name) end
        local shared = {Items="Items", Appearance="Appearance"}
        local players = { added = {}, removing = {} }
        players.PlayerAdded = { Connect = function(_, connect) table.insert(players.added, connect) end }
        players.PlayerRemoving = { Connect = function(_, connect) table.insert(players.removing, connect) end }
        players.GetPlayers = function() return {} end
        local records = {}
        local clock = 1000
        local token = 0
        local failAfterWrite = false
        local os = { time = function() return clock end, clock = function() return clock end }
        local task = { wait = function() end, spawn = function() end }
        local warn = function() end
        local datastore = { UpdateAsync = function(_, key, transform)
            local nextValue = transform(records[key])
            if nextValue then
                records[key] = nextValue
            end
            if failAfterWrite then
                error("resposta perdida depois de gravar")
            end
            return nextValue
        end }
        local game = {
            BindToClose = function() end,
            GetService = function(_, name)
                if name == "ReplicatedStorage" then return { Shared = shared } end
                if name == "RunService" then return { IsStudio = function() return false end } end
                if name == "Players" then return players end
                if name == "DataStoreService" then return { GetDataStore = function() return datastore end } end
                if name == "HttpService" then
                    return { GenerateGUID = function() token += 1; return tostring(token) end }
                end
                error(name)
            end,
        }
        local script = { Parent = {
            AvatarConfig = "AvatarConfig", Careers = "Careers", InventoryRules = "InventoryRules",
            Economy = "Economy", Profiles = "Profiles", ProfileSchema = "ProfileSchema",
            Parent = { Settings = "Settings" },
        }}
        local Color3 = { fromRGB = function() return {} end }
        modules.Profiles = { Get = function(player) return active[player] end }
    `;
    const sources = Object.entries(modules).map(([name, file]) => {
        const source = readFileSync(new URL('../src/' + file, import.meta.url), 'utf8');
        return `modules.${name} = (function()\n${source}\nend)()`;
    });
    const profiles = readFileSync(new URL('../src/server/Services/Profiles.luau', import.meta.url), 'utf8');
    const profileFactory = `local function newProfileService()\n${profiles}\nend`;
    const spec = readFileSync(new URL('./rules.spec.luau', import.meta.url), 'utf8');
    const [count] = await state.loadstring(
        [prelude, ...sources, profileFactory, spec].join('\n'), 'rules', true,
    )();
    console.log(count, 'cenários executados com sucesso.');
} finally {
    state.destroy();
}
