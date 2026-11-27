#!/usr/bin/env node
// Records search, stream and autocomplete of the three keyless streaming
// plugins live and writes sanitised fixtures. Not run by CI.
//
//   node record-fixtures.js <plugins-clone> <out-dir>
'use strict';
const fs = require('fs');
const path = require('path');

const [clone, outDir] = process.argv.slice(2);
if (!clone || !outDir) {
  console.error('usage: node record-fixtures.js <plugins-clone> <out-dir>');
  process.exit(2);
}
const { runScript } = require(path.join(clone, 'tools', 'source_harness.js'));

const slugs = ['audius', 'jamendo', 'youtube'];
// The app runtime's limits: MAX_FETCH_SENDS and the 20 s run timeout.
const limits = { maxSends: 10, deadlineSec: 20 };
const forbidden = /ip=|sig=|signature=|token=|key=/;

/**
 * Keeps scheme and path of the stream url; the query becomes fixture=1. A
 * Google video cache host (its label names the recorder's nearby node) becomes
 * a fixed neutral one.
 */
function sanitiseStream(data) {
  const u = new URL(data.url);
  const host = /\.googlevideo\.com$/.test(u.hostname) ? 'rr1---sn-fixture.googlevideo.com' : u.host;
  return { ...data, url: `${u.protocol}//${host}${u.pathname}?fixture=1` };
}

function firstTrackId(search) {
  const cards = [...(search.sections || []).flatMap((s) => s.items || []), ...(search.items || [])];
  const card = cards.find((c) => (c.kind || 'track') === 'track');
  return card ? card.id : null;
}

let failed = false;
for (const slug of slugs) {
  let storage = {};
  let trackId = null;
  const steps = [
    ['search', () => ({ query: 'Blinding Lights' })],
    ['stream', () => ({ id: trackId })],
    ['autocomplete', () => ({ query: 'blinding' })],
  ];
  for (const [script, makeInput] of steps) {
    let status = 'skipped', sends = 0, durationMs = 0, data;
    try {
      const input = makeInput();
      if (script === 'stream' && !trackId) throw new Error('no track id from search');
      const run = runScript(`${script}.js`, input, { pluginSlug: slug, initialStorage: storage, ...limits });
      storage = run.storage || storage;
      sends = run.metrics.sends;
      durationMs = run.metrics.durationMs;
      const result = run.result || {};
      status = result.status === 'ok' ? 'ok' : result.status || 'error';
      if (status === 'ok') data = result.data;
    } catch (e) {
      status = `exception:${String(e.message).slice(0, 60)}`;
    }
    console.log(`${slug} ${script} ${status} ${sends} ${durationMs}`);
    if (status !== 'ok') { failed = true; continue; }
    if (script === 'search') trackId = firstTrackId(data);
    if (script === 'stream') data = sanitiseStream(data);
    const file = path.join(outDir, slug, `${script}.json`);
    const text = JSON.stringify(data, null, 2) + '\n';
    // Checked before anything is written: no unsanitised file is left behind.
    if (forbidden.test(text)) {
      console.error(`unsanitised content for ${slug} ${script}; not written`);
      process.exitCode = 1;
      continue;
    }
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, text);
  }
}
if (failed) console.error('some scripts did not answer ok; hand-write those fixtures');
