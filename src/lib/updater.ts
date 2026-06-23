'use client';

/**
 * Auto-Updater integration for Tauri.
 *
 * In dev (browser), this is a no-op.
 * In production (Tauri .exe), it checks for updates on startup and shows a dialog.
 *
 * Setup:
 * 1. Configure tauri.conf.json plugins.updater.endpoints to point to your latest.json URL
 * 2. Run `bun run tauri:build` to produce a signed .exe + .sig file
 * 3. Upload both files to GitHub Releases
 * 4. Update latest.json with the correct version + URL + signature
 *
 * Because we don't code-sign (private project), Windows SmartScreen will warn users
 * the first time they run the .exe. They click "More info" → "Run anyway" and it
 * won't bother them again for that version.
 */

import { useEffect, useState } from 'react';

interface UpdaterState {
  checking: boolean;
  updateAvailable: boolean;
  downloading: boolean;
  downloaded: boolean;
  error: string | null;
  version: string | null;
  notes: string | null;
}

export function useUpdater() {
  const [state, setState] = useState<UpdaterState>({
    checking: false,
    updateAvailable: false,
    downloading: false,
    downloaded: false,
    error: null,
    version: null,
    notes: null,
  });

  useEffect(() => {
    // Only run in Tauri (window.__TAURI__ exists when running as .exe)
    const w = window as unknown as { __TAURI__?: unknown };
    if (!w.__TAURI__) {
      // Browser dev mode — no updater
      return;
    }

    let cancelled = false;

    async function checkForUpdates() {
      try {
        setState((s) => ({ ...s, checking: true, error: null }));
        const { check } = await import('@tauri-apps/plugin-updater');
        const update = await check();
        if (cancelled) return;
        if (update) {
          setState((s) => ({
            ...s,
            checking: false,
            updateAvailable: true,
            version: update.version,
            notes: update.body,
          }));
        } else {
          setState((s) => ({ ...s, checking: false, updateAvailable: false }));
        }
      } catch (err) {
        if (cancelled) return;
        setState((s) => ({
          ...s,
          checking: false,
          error: err instanceof Error ? err.message : String(err),
        }));
      }
    }

    checkForUpdates();
    return () => {
      cancelled = true;
    };
  }, []);

  async function downloadAndInstall() {
    try {
      setState((s) => ({ ...s, downloading: true, error: null }));
      const { check } = await import('@tauri-apps/plugin-updater');
      const update = await check();
      if (!update) {
        setState((s) => ({ ...s, downloading: false }));
        return;
      }
      await update.downloadAndInstall((event: { event: string; data?: { chunkLength?: number; contentLength?: number } }) => {
        switch (event.event) {
          case 'Started':
            break;
          case 'Progress':
            break;
          case 'Finished':
            setState((s) => ({ ...s, downloading: false, downloaded: true }));
            break;
        }
      });
    } catch (err) {
      setState((s) => ({
        ...s,
        downloading: false,
        error: err instanceof Error ? err.message : String(err),
      }));
    }
  }

  return { ...state, downloadAndInstall };
}
