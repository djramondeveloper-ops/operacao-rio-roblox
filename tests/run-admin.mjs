import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const runtime = process.argv[2];
const { LuauState } = await import(runtime ? pathToFileURL(resolve(runtime)).href : 'luau-web');
const state = await LuauState.createAsync();
try {
    const names = ['Config', 'Permissions', 'Persistence', 'Audit', 'Arguments', 'Moderation', 'Commands', 'Actions', 'Service'];
    const modules = {
        Items: 'shared/Items.luau', AdminCatalog: 'shared/AdminCatalog.luau',
        InventoryRules: 'server/Services/InventoryRules.luau', Economy: 'server/Services/Economy.luau',
        Inventory: 'server/Services/Inventory.luau',
        ...Object.fromEntries(names.map(name => [name, 'server/Admin/' + name + '.luau'])),
    };
    const prelude = readFileSync(new URL('./admin-fixtures.luau', import.meta.url), 'utf8');
    const sources = Object.entries(modules).map(([name, file]) => {
        const source = readFileSync(new URL('../src/' + file, import.meta.url), 'utf8');
        return `modules.${name} = (function()\n${source}\nend)()`;
    });
    const spec = readFileSync(new URL('./admin.spec.luau', import.meta.url), 'utf8');
    const [count] = await state.loadstring([prelude, ...sources, spec].join('\n'), 'admin', true)();
    console.log(count, 'cenários administrativos executados.');
} finally {
    state.destroy();
}
