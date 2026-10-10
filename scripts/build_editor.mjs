import { build } from 'esbuild';
import { readFile, writeFile } from 'node:fs/promises';
const output = 'assets/editor/editor.js';
const result = await build({
  entryPoints: ['scripts/editor/editor.mjs'], bundle: true, minify: true,
  target: ['safari16', 'chrome120'], format: 'iife', outfile: output,
  legalComments: 'eof', write: false, metafile: true,
});
const bytes = result.outputFiles[0].contents;
const roots = [...new Set(Object.keys(result.metafile.inputs).map(path =>
  path.match(/^node_modules\/(?:@[^/]+\/)?[^/]+/)?.[0]).filter(Boolean))].sort();
const licenses = ['Plane Mobile rich editor — bundled open-source licenses\n'];
for (const root of roots) {
  const pkg = JSON.parse(await readFile(`${root}/package.json`, 'utf8'));
  let license;
  for (const name of ['LICENSE', 'LICENSE.md', 'LICENSE-MIT', 'LICENSE.txt']) {
    try { license = await readFile(`${root}/${name}`, 'utf8'); break; } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
  }
  if (!license) throw new Error(`Bundled dependency license missing: ${pkg.name}`);
  licenses.push(`${pkg.name} ${pkg.version}\n${license}`);
}
const licenseBytes = Buffer.from(licenses.join('\n\n'));
if (process.argv.includes('--check')) {
  if (!Buffer.from(bytes).equals(await readFile(output))) throw new Error('Editor asset is stale. Run npm run build:editor.');
  if (!licenseBytes.equals(await readFile('assets/editor/LICENSES.txt'))) throw new Error('Editor licenses are stale. Run npm run build:editor.');
} else {
  await writeFile(output, bytes);
  await writeFile('assets/editor/LICENSES.txt', licenseBytes);
}
